//
//  JoyConConmunication.swift
//  Magic Joy-Con
//
//  Created by SymenYang on 2018/5/6.
//  Copyright © 2018年 SymenYang. All rights reserved.
//

import Foundation
import Cocoa
import IOKit.hid
import Quartz

class joyconCommunication {
    var dataPutIn = UnsafeMutablePointer<uint8>.allocate(capacity: 15)
    var globalPacketNumber : uint8 = 0x00
    var inputData = UnsafeMutablePointer<uint8>.allocate(capacity: 50)
    let inputLength = 50
    
    var buttonCallBack : ( (uint8,uint8,uint8,uint16,uint16,uint16,uint16) -> () )!
    var accGyroCallBack : ( ([Double],[Double]) -> () )!
    var modeCallBack : ( (uint8) -> () )!
    var alwaysCallBack : (() -> ())!
    
    func initBasicOutput() {
        self.dataPutIn[0] = 0x01
        self.dataPutIn[1] = self.globalPacketNumber
        self.globalPacketNumber += 1
        if self.globalPacketNumber > 0xF {
            self.globalPacketNumber = 0x0
        }
        self.dataPutIn[2] = 0x00
        self.dataPutIn[3] = 0x01
        self.dataPutIn[4] = 0x40
        self.dataPutIn[5] = 0x40
        self.dataPutIn[6] = 0x00
        self.dataPutIn[7] = 0x01
        self.dataPutIn[8] = 0x40
        self.dataPutIn[9] = 0x40
        //above are rumble data to control vibration . Set to default to not use it
        self.dataPutIn[10] = 0x00
        self.dataPutIn[11] = 0x00
        self.dataPutIn[12] = 0x00
        self.dataPutIn[13] = 0x00
        self.dataPutIn[14] = 0x00
    }
    
    func __encodeFreq(Freq: Double) -> uint8{
        var freq = Freq
        if freq < 41.0 {
            freq = 41.0
        }
        else if freq > 1252.0 {
            freq = 1252.0
        }
        let encoded_hex_freq : uint8 = UInt8(round(log2(freq/10.0)*32.0))
        return encoded_hex_freq
    }
    
    func __encodeAmp(Amp: Double) -> uint8 {
        var amp = Amp
        if amp <= 0 {
            amp = 0.0
            return 0
        }
        if amp > 1 {
            amp = 1.0
        }
        if (amp < 0.117) {return UInt8(Double(UInt8(log2(amp * 1000) * 32) - 0x60) / (5 - (pow(2.0, amp))) - 1)}
        if (amp >= 0.117 && amp < 0.23) {return (UInt8(log2(amp * 1000) * 32) - 0x60) - 0x5c}
        if (amp >= 0.23) {return UInt8(((UInt16(log2(amp * 1000) * 32) - 0x60) * 2) - 0xf6)}
        return 0
    }
    
    func __encodeLowAmp(Amp: Double) -> uint16 {
        var encoded : uint8 = UInt8(self.__encodeAmp(Amp: Amp) / 2)
        let evenOrOdd : uint8 = encoded % 2
        var bytes : [uint8] = [0,0]
        
        if (evenOrOdd > 0) {
            // odd
            bytes[0] = 0x80
            encoded = encoded - 1
        }
        
        encoded = encoded / 2
        
        bytes[1] = 0x40 + encoded
        
        // if you wanted to combine them:
        let byte : UInt16 = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
        return byte
    }
    
    func rumbleSend(device : IOHIDDevice,isLeft : Bool,highFreq : Double,highAmp : Double,lowFreq : Double,lowAmp : Double,debug : Bool = false) {
        self.initBasicOutput()
        // Encode Part
        var encodeByte = UInt16(self.__encodeFreq(Freq: highFreq))
        var hfT : UInt16 = 0
        var hf : UInt8 = 0
        var hfA : UInt8 = 0
        hfT = (encodeByte - 0x60) << 2
        if hfT >= 256 {
            hfA = UInt8(hfT >> 8)
            hf = UInt8(hfT & 0xff)
        }
        else {
            hf = UInt8(hfT)
        }
        let hAMPByte = self.__encodeAmp(Amp: highAmp)
        hfA += hAMPByte
        
        var lfcast = lowFreq
        var lf : UInt8 = 0
        if lfcast > 626.0 {
            lfcast = 626.0
        }
        encodeByte = UInt16(self.__encodeFreq(Freq: lfcast))
        lf = UInt8(encodeByte - 0x40)
        let lAMP2Byte = self.__encodeLowAmp(Amp: lowAmp)
        lf += UInt8(lAMP2Byte >> 8)
        let lfA : UInt8 = UInt8(lAMP2Byte & 0xff)
        
        let Base : Int = isLeft ? 2 : 6
        self.dataPutIn[Base] = hf
        self.dataPutIn[Base + 1] = hfA
        self.dataPutIn[Base + 2] = lf
        self.dataPutIn[Base + 3] = lfA
        
        let length = 12
        let ret = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x10, self.dataPutIn, length)
        if !debug {
            return
        }
        print(hf," ",hfA," ",lf," ",lfA)
        if ret != kIOReturnSuccess {
            print("test unsuccess")
        }
        else {
            print("test success")
        }
    }
    
    func changeMode(device : IOHIDDevice,Mode : uint8 = 0x31,debug : Bool = true) {
        self.initBasicOutput()
        self.dataPutIn[10] = 0x03
        self.dataPutIn[11] = Mode
        let length = 12
        let ret = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x01, self.dataPutIn, length)
        
        if !debug {
            return
        }
        
        if ret != kIOReturnSuccess {
            print("open full response unsuccess")
        }
        else {
            print("open full response success")
        }
        
    }
    
    func turnIMU(device : IOHIDDevice,ON : Bool = true,debug : Bool = true) {
        self.initBasicOutput()
        self.dataPutIn[10] = 0x40
        self.dataPutIn[11] = ON ? 0x01 : 0x00
        let length = 12
        let ret = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x01, self.dataPutIn, length)
        
        if !debug {
            return
        }
        
        if ret != kIOReturnSuccess {
            print("open IMU unsuccess")
        }
        else {
            print("open IMU success")
        }
    }
    
    func turnVibration(device : IOHIDDevice,ON : Bool = true,debug : Bool = true) {
        self.initBasicOutput()
        self.dataPutIn[10] = 0x48
        self.dataPutIn[11] = ON ? 0x01 : 0x00
        let length = 12
        let ret = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x01, self.dataPutIn, length)
        
        if !debug {
            return
        }
        
        if ret != kIOReturnSuccess {
            print("open vibration unsuccess")
        }
        else {
            print("open vibration success")
        }
    }
    
    let callback_report : IOHIDReportCallback = {context, result, sender, type, reportID,report,length in
        // get self indicator
        let myself = context?.load(as: joyconCommunication.self)
        if myself?.modeCallBack != nil {
            myself?.modeCallBack(report[0])
        }
        // convert 2byte to a Double
        func convert2Byte(a:UInt8,b:UInt8) -> Double {
            let num1 : UInt32 = UInt32(a)
            let num2 : UInt32 = UInt32(b)
            var tmp : Int32 = Int32(num1 + num2 * 256)
            if tmp >= 32768 {
                tmp -= 65536
            }
            return Double(tmp)
        }
        //call always recall func
        if myself?.alwaysCallBack != nil {
            myself?.alwaysCallBack()
        }
        
        //Not in use
        if report[0] == 0x3f {
            if myself?.buttonCallBack != nil {
                //myself?.buttonCallBack(report[1],report[2],report[3])
            }
        }
        
        if report[0] == 0x31 || report[0] == 0x30 {
            if myself?.buttonCallBack != nil {
                let stickData : [UInt16] = [UInt16(report[6]),UInt16(report[7]),UInt16(report[8])
                    ,UInt16(report[9]),UInt16(report[10]),UInt16(report[11])]
                let LStickH = stickData[0] | (stickData[1] & 0xF) << 8
                let RStickH = stickData[3] | (stickData[4] & 0xF) << 8
                let LStickV = stickData[1] >> 4 | (stickData[2] << 4)
                let RStickV = stickData[4] >> 4 | (stickData[5] << 4)
                myself?.buttonCallBack(report[3],report[4],report[5],
                                       LStickH,LStickV,RStickH,RStickV)
            }
            if myself?.accGyroCallBack != nil {
                var retAcc : [Double] = [0,0,0,0,0,0,0,0,0]
                var retGyro : [Double] = [0,0,0,0,0,0,0,0,0]
                var accCount : Int = 0
                var gyroCount : Int = 0
                for index in 7...24 {
                    let num1 = report[index * 2 - 1]
                    let num2 = report[index * 2]
                    let num = convert2Byte(a: num1, b: num2)
                    if (index % 6 <= 3 && index % 6 != 0) {
                        retAcc[accCount] = num * 0.00244
                        accCount += 1
                    }
                    else {
                        retGyro[gyroCount] = num * 0.06103
                        gyroCount += 1
                    }
                }
                myself?.accGyroCallBack(retAcc,retGyro)
            }
        }
    }
    
    func registerResponse(device : IOHIDDevice) {
        let context = UnsafeMutableRawPointer.allocate(byteCount: 600, alignment: 4)
        context.storeBytes(of: self, as: joyconCommunication.self)
        IOHIDDeviceRegisterInputReportCallback(device,self.inputData,self.inputLength,self.callback_report,context)
    }
}
