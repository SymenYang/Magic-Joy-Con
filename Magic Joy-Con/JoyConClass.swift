//
//  JoyConClass.swift
//  MyJoyCon
//
//  Created by SymenYang on 2018/4/9.
//  Copyright © 2018年 MyName. All rights reserved.
//

import Foundation
import Cocoa
import IOKit.hid
import Quartz

class macOperation : NSObject,NSUserNotificationCenterDelegate{
    
    func getEvent() -> CGEvent! {
        return CGEvent.init(source: nil)
    }
    
    func moveMouse(dx : Double,dy : Double,condition : [Bool]) {
        if condition[0] {
            self.dragMouseLeft(dx: dx, dy: dy)
        }
        else if condition[1] {
            self.dragMouseRight(dx: dx, dy: dy)
        }
        else {
            self.moveMouse(dx: dx, dy: dy)
        }
    }
    
    func moveMouse(dx : Double,dy : Double) {
        let event = self.getEvent()
        let point = event!.location
        CGWarpMouseCursorPosition(CGPoint(x: Double(point.x) + dx, y: Double(point.y) + dy))
    }
    
    func downMouseLeft () {
        let event = self.getEvent()
        let mouseDown = CGEvent(mouseEventSource: nil,
                                mouseType: .leftMouseDown,
                                mouseCursorPosition: event!.location,
                                mouseButton: .left
        )
        mouseDown?.post(tap: .cghidEventTap)
    }
    
    func downMouseRight () {
        let event = self.getEvent()
        let mouseDown = CGEvent(mouseEventSource: nil,
                                mouseType: .rightMouseDown,
                                mouseCursorPosition: event!.location,
                                mouseButton: .left
        )
        mouseDown?.post(tap: .cghidEventTap)
    }
    
    func dragMouseLeft(dx : Double,dy : Double) {
        let event = self.getEvent()
        let point = event!.location
        let mouseDrag = CGEvent(mouseEventSource: nil,
                                              mouseType: .leftMouseDragged,
                                              mouseCursorPosition: CGPoint(x: Double(point.x) + dx, y: Double(point.y) + dy),
                                              mouseButton: .left
        )
        mouseDrag?.post(tap: .cghidEventTap)
    }
    
    func dragMouseRight(dx : Double,dy : Double) {
        let event = self.getEvent()
        let point = event!.location
        let mouseDrag = CGEvent(mouseEventSource: nil,
                                mouseType: .rightMouseDragged,
                                mouseCursorPosition: CGPoint(x: Double(point.x) + dx, y: Double(point.y) + dy),
                                mouseButton: .left
        )
        mouseDrag?.post(tap: .cghidEventTap)
    }
    
    func upMouseLeft() {
        let event = self.getEvent()
        let mouseUp = CGEvent(mouseEventSource: nil,
                              mouseType: .leftMouseUp,
                              mouseCursorPosition: event!.location,
                              mouseButton: .left
        )
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    func upMouseRight() {
        let event = self.getEvent()
        let mouseUp = CGEvent(mouseEventSource: nil,
                              mouseType: .rightMouseUp,
                              mouseCursorPosition: event!.location,
                              mouseButton: .left
        )
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    func mouseScroll(length : Int32) {
        if #available(OSX 10.13, *) {
            let mouseScroll = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: length, wheel2: 0, wheel3: 0)
            mouseScroll?.post(tap: .cghidEventTap)
        } else {
            print("Scroll failed")
            // Fallback on earlier versions
        }
    }
    
    //KEYBOARD
    
    func downKeyboard(code : CGKeyCode) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true)
        keyDown?.post(tap: .cghidEventTap)
    }
    
    func upKeyboard(code : CGKeyCode) {
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func downKeyboardWithMask(code : CGKeyCode,mask: CGEventFlags) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true)
        keyDown?.flags = mask
        keyDown?.post(tap: .cghidEventTap)
    }
    
    func upKeyboardWithMask(code : CGKeyCode,mask: CGEventFlags) {
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false)
        keyUp?.flags = mask
        keyUp?.post(tap: .cghidEventTap)
    }
    
    //Delegate
    func showNotification(title: String, subtitle: String, informativeText: String, contentImage: NSImage! = nil) {
        
        let notification = NSUserNotification()
        
        notification.title = title
        notification.subtitle = subtitle
        notification.informativeText = informativeText
        notification.contentImage = contentImage
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.delegate = self
        NSUserNotificationCenter.default.deliver(notification)
        
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter,
                                shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

class joyconData {
    var device : IOHIDDevice
    var communicator : joyconCommunication
    var macOperator : macOperation
    
    init (device : IOHIDDevice,communicator : joyconCommunication) {
        self.device = device
        self.communicator = communicator
        self.macOperator = macOperation()
        self.communicator.buttonCallBack = self.dealButtonInfo
        self.communicator.accGyroCallBack = self.dealAccGyroInfo
        self.defaultButtonOption()
    }
    
    var is_tracing : Bool = false //ZR
    var lastStatus : [Bool] = [false,false,false,false,false,false,false,false,false,false,false]
    var status : [Bool] = [false,false,false,false,false,false,false,false,false,false,false]
    var actionOnDown : [(() -> ())?] = [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
    var actionOnUp : [(() -> ())?] =  [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
    var actionOnHold : [(() -> ())?] =  [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
    var actionOnRelease : [(() -> ())?] =  [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
    var LstickAction : ((uint16,uint16) -> ())!
    var RstickAction : ((uint16,uint16) -> ())!
    
    enum buttonNum : Int {
        case A = 0
        case B = 1
        case X = 2
        case Y = 3
        case R = 4
        case add = 5
        case SR = 6
        case SL = 7
        case stick = 8
        case home = 9
        case ZR = 10
    }
    
    enum onSituation : Int {
        case Down = 0
        case Up = 1
        case Hold = 2
        case Release = 3
    }
    
    func registerButtonFunction(onWhat : onSituation, key : buttonNum, function : @escaping () -> ()) {
        if onWhat == onSituation.Down {
            self.actionOnDown[key.rawValue] = function
        }
        if onWhat == onSituation.Up {
            self.actionOnUp[key.rawValue] = function
        }
        if onWhat == onSituation.Hold {
            self.actionOnHold[key.rawValue] = function
        }
        if onWhat == onSituation.Release {
            self.actionOnRelease[key.rawValue] = function
        }
    }
    
    func dealButtonInfo(button1 : uint8, button2 : uint8, button3 : uint8,
                        LStickH : uint16, LStickV : uint16,
                        RStickH : uint16, RStickV : uint16) {
        //print(button1," ",button2," ",button3)
        //print(LStickV," ",LStickH)
        //print(RStickV," ",RStickH)
        self.status[0] = ((button1 >> 3) & 0x01) == 1
        self.status[1] = ((button1 >> 2) & 0x01) == 1
        self.status[2] = ((button1 >> 1) & 0x01) == 1
        self.status[3] = (button1 & 0x01) == 1
        self.status[4] = ((button1 >> 6) & 0x01) == 1
        self.status[5] = ((button2 >> 1) & 0x01) == 1
        self.status[6] = ((button1 >> 4) & 0x01) == 1
        self.status[7] = ((button1 >> 5) & 0x01) == 1
        self.status[8] = ((button2 >> 2) & 0x01) == 1
        self.status[9] = ((button2 >> 4) & 0x01) == 1
        self.status[10] = ((button1 >> 7) & 0x01) == 1
        for i in 0...10 {
            if self.status[i] != self.lastStatus[i] {
                if self.status[i] && self.actionOnDown[i] != nil {
                    self.actionOnDown[i]!()
                }
                if !self.status[i] && self.actionOnUp[i] != nil {
                    self.actionOnUp[i]!()
                }
            }
            else {
                if self.status[i] && self.actionOnHold[i] != nil {
                    self.actionOnHold[i]!()
                }
                if !self.status[i] && self.actionOnRelease[i] != nil {
                    self.actionOnRelease[i]!()
                }
            }
            self.lastStatus[i] = self.status[i]
        }
        if self.LstickAction != nil {
            self.LstickAction(LStickH,LStickV)
        }
        if self.RstickAction != nil {
            self.RstickAction(RStickH,RStickV)
        }
    }
    
    var rotation : [Double] = [0.0,0.0,0.0]
    let rotationCast : [Double] = [3.0,3.0,3.0]
    var lastRotation : [Double] = [0.0,0.0,0.0]
    let moveCast : [Double] = [1.0,1.0]
    var moveSpeed = 0.5
    
    func resetRotation() {
        self.rotation[0] = 0.0
        self.rotation[1] = 0.0
        self.rotation[2] = 0.0
    }
    
    func dealAccGyroInfo(accData : [Double], gyroData : [Double]) {
        for index in 0...2 {
            var rotatex = gyroData[index * 3]
            var rotatey = gyroData[index * 3 + 1]
            var rotatez = gyroData[index * 3 + 2]
            rotatex = fabs(rotatex) > self.rotationCast[0] ? rotatex:0.0
            rotatey = fabs(rotatey) > self.rotationCast[1] ? rotatey:0.0
            rotatez = fabs(rotatez) > self.rotationCast[2] ? rotatez:0.0
            self.rotation[0] += rotatex * 0.005
            self.rotation[1] += rotatey * 0.005
            self.rotation[2] += rotatez * 0.005
        }
        //print(rotation)
        if self.status[10] {
            var dx = (gyroData[2] + gyroData[5] + gyroData[8] ) / 3
            var dy = -(gyroData[1] + gyroData[4] + gyroData[7]) / 3 - 0.7
            //print(dx," ",dy)
            dx = fabs(dx) > self.moveCast[1] ? dx : 0.5 * dx
            dy = fabs(dy) > self.moveCast[0] ? dy : 0.5 * dy
            dx = fabs(dx) > 1 / self.moveSpeed ? dx : 0.0
            dy = fabs(dy) > 1 / self.moveSpeed ? dy : 0.0
            self.macOperator.moveMouse(dx: dx * self.moveSpeed, dy: dy * self.moveSpeed,condition : self.status)
            for index in 0...2{
                self.lastRotation[index] = self.rotation[index]
            }
        }else{
            self.resetRotation()
        }
    }

    var _stable_H_L : uint16 = 1 << 13
    var _stable_V_L : uint16 = 1 << 13
    var _stable_H_R : uint16 = 1 << 13
    var _stable_V_R : uint16 = 1 << 13
    
    func RAction(H : uint16,V : uint16) {
        if self._stable_H_R == 1 << 13 {
            self._stable_H_R = H
            self._stable_V_R = V
        }
        let dH =  Int32((H - self._stable_H_R) / 200)
        let dV =  -Int32((V - self._stable_V_R) / 200)
        if dH != 0 && dV != 0 {
            self.macOperator.moveMouse(dx: Double(dH), dy: Double(dV))
        }
    }
    
    func defaultButtonOption() {
        self.registerButtonFunction(onWhat: .Down, key: .A, function :{
            self.macOperator.downMouseLeft()
        })
        self.registerButtonFunction(onWhat: .Up, key: .A, function:{
            self.macOperator.upMouseLeft()
        })
        
        self.registerButtonFunction(onWhat: .Down, key: .B, function: {
            self.macOperator.downKeyboard(code: 0x3D)
            //self.macOperator.downKeyboardWithMask(code: 0x22, mask: .maskShift)
            //self.macOperator.upKeyboardWithMask(code: 0x22, mask: .maskShift)
            //self.macOperator.upKeyboard(code: 0x38)
        })
        self.registerButtonFunction(onWhat: .Up, key: .B, function: {
            //self.macOperator.upKeyboardWithMask(code: 0x7E, mask: .maskControl)
            self.macOperator.upKeyboard(code: 0x3D)
        })
        
        self.registerButtonFunction(onWhat: .Hold, key: .X, function: {
            self.macOperator.mouseScroll(length: 10)
        })
        
        self.registerButtonFunction(onWhat: .Hold, key: .Y, function: {
            self.macOperator.mouseScroll(length: -10)
        })
        
        self.registerButtonFunction(onWhat: .Down, key: .SL, function: {
            self.macOperator.downKeyboardWithMask(code: 0x2b, mask: .maskCommand)
            //self.macOperator.upKeyboardWithMask(code: 0x2b, mask: .maskCommand)
            self.macOperator.upKeyboard(code: 0x2b)
        })
        
        
        self.registerButtonFunction(onWhat: .Down, key: .SR, function: {
            self.macOperator.downKeyboardWithMask(code: 0x2f, mask: .maskCommand)
            //self.macOperator.upKeyboardWithMask(code: 0x2f, mask: .maskCommand)
            self.macOperator.upKeyboard(code: 0x2f)
        })
        
        self.registerButtonFunction(onWhat: .Down, key: .R, function:{
            self.macOperator.downMouseRight()
        })
        self.registerButtonFunction(onWhat: .Up, key: .R, function:{
            self.macOperator.upMouseRight()
        })
        
        self.registerButtonFunction(onWhat: .Down, key: .home, function: {
            if self.RstickAction == nil {
                self.RstickAction = self.RAction
            }
            else {
                self.RstickAction = nil
            }
        })
        
        self.registerButtonFunction(onWhat: .Down, key: .add, function: {
            self.moveSpeed += 0.25
            if self.moveSpeed == 1.25 {
                self.moveSpeed = 0.25
            }
            self.macOperator.showNotification(title: "Joy-Con Controller", subtitle: "Changed movespeed", informativeText: "Changed movespeed into " + String(self.moveSpeed))
        })
        
    }
    
    
}

class joyconCommunication {
    var dataPutIn = UnsafeMutablePointer<uint8>.allocate(capacity: 15)
    var globalPacketNumber : uint8 = 0x00
    var inputData = UnsafeMutablePointer<uint8>.allocate(capacity: 50)
    let inputLength = 50
    
    var debugString = "test"
    var buttonCallBack : ( (uint8,uint8,uint8,uint16,uint16,uint16,uint16) -> () )!
    var accGyroCallBack : ( ([Double],[Double]) -> () )!
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
        self.dataPutIn[10] = 0x00
        self.dataPutIn[11] = 0x00
        self.dataPutIn[12] = 0x00
        self.dataPutIn[13] = 0x00
        self.dataPutIn[14] = 0x00
    }
    
    func changeMode(device : IOHIDDevice,Mode : uint8 = 0x31,debug : Bool = true) {
        self.initBasicOutput()
        self.dataPutIn[10] = 0x03
        self.dataPutIn[11] = 0x31
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
    
    func registerResponse(device : IOHIDDevice) {
        
        let callback_report : IOHIDReportCallback = {context, result, sender, type, reportID,report,length in
            
            //print(report[0])
            
            let myself = context?.load(as: joyconCommunication.self)
            func convert2Byte(a:UInt8,b:UInt8) -> Double {
                let num1 : UInt32 = UInt32(a)
                let num2 : UInt32 = UInt32(b)
                var tmp : Int32 = Int32(num1 + num2 * 256)
                if tmp >= 32768 {
                    tmp -= 65536
                }
                return Double(tmp)
            }
            //Not in use
            if report[0] == 0x3f {
                if myself?.buttonCallBack != nil {
                    //myself?.buttonCallBack(report[1],report[2],report[3])
                }
            }
            
            if report[0] == 0x31 {
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
        
        let context = UnsafeMutableRawPointer.allocate(bytes: 600, alignedTo: 4)
        context.storeBytes(of: self, as: joyconCommunication.self)
        IOHIDDeviceRegisterInputReportCallback(device,self.inputData,self.inputLength,callback_report,context)
    }
}
