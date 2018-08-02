//
//  VibrationController.swift
//  Magic Joy-Con
//
//  Created by SymenYang on 2018/4/18.
//  Copyright © 2018年 SymenYang. All rights reserved.
//

import Foundation
import Cocoa
import IOKit.hid
import Quartz

class vibrationData {
    var time : Double = 0
    var highFreq : Double = 0
    var highAmp : Double = 0
    var lowFreq : Double = 0
    var lowAmp : Double = 0
    
    var lock : Bool = false
    var unLock : Bool = false
    
    init(time : Double,lock : Bool = false,unLock : Bool = false,highFreq : Double = 320.0,highAmp : Double = 0.0,lowFreq : Double = 320.0,lowAmp : Double = 0.0 ) {
        self.time = time
        self.highFreq = highFreq
        self.highAmp = highAmp
        self.lowFreq = lowFreq
        self.lowAmp = lowAmp
        self.lock = lock
        self.unLock = unLock
    }
}

class vibrationController {
    var device : IOHIDDevice
    var queue : [vibrationData] = []
    var communicator : joyconCommunication
    var locked : Bool = false
    var isLeft : Bool
    let deltaTime : Double // min gap time / 2 in sec
    init(device : IOHIDDevice,communicator : joyconCommunication,isLeft : Bool,deltaTime : Double = 0.0075) {
        self.device = device
        self.communicator = communicator
        self.isLeft = isLeft
        self.deltaTime = deltaTime
    }
    
    func oneStep() {
        let timeNow = CFAbsoluteTimeGetCurrent()
        var signal : vibrationData! = nil
        if self.queue.count == 0 {
            return
        }
        while self.queue[0].time - timeNow < deltaTime {
            signal = self.queue.removeFirst()
            if self.queue.count == 0 {
                break
            }
        }
        if signal != nil {
            self.communicator.rumbleSend(device: self.device, isLeft: self.isLeft, highFreq: signal.highFreq, highAmp: signal.highAmp, lowFreq: signal.lowFreq, lowAmp: signal.lowAmp,debug: false)
        }
    }
    
    func addVibration(startTimeFromNow : Double,duration : Double,highFreq : Double,highAmp : Double,LowFreq : Double,lowAmp : Double,lock : Bool = false) -> Bool {
        var index : Int = 0
        var haveLock : Bool = false
        while index < self.queue.count && self.queue[index].time < startTimeFromNow {
            index += 1
            if haveLock {
                haveLock = !self.queue[index].unLock
            }
            else {
                haveLock = self.queue[index].lock
            }
        }
        if haveLock {
            return false
        }
        let nowTime = CFAbsoluteTimeGetCurrent()
        let repeatTime : Int = duration > 1 ? Int(round(duration / 1.0)) : 1
        for i in 0..<repeatTime {
            self.queue.insert(vibrationData(time: startTimeFromNow + nowTime + Double(i) * 1.0,
                                            lock: lock,
                                            unLock: false,
                                            highFreq: highFreq,
                                            highAmp: highAmp,
                                            lowFreq: LowFreq,
                                            lowAmp: lowAmp
                                            ),
                              at: index + i)
        }
        self.queue.insert(vibrationData(time: startTimeFromNow + duration + nowTime, lock: false, unLock: lock), at : index + repeatTime)
        return true
    }
}
