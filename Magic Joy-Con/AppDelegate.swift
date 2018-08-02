//
//  AppDelegate.swift
//  Magic Joy-Con
//
//  Created by SymenYang on 2018/4/11.
//  Copyright © 2018年 SymenYang. All rights reserved.
//

import Cocoa
import Foundation
import IOKit.hid
import Quartz

let opts = NSDictionary(object: kCFBooleanTrue,
                        forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    ) as CFDictionary

func getPermission () {
    guard AXIsProcessTrustedWithOptions(opts) == true else { return }
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault,
                                 IOOptionBits(kIOHIDOptionsTypeNone))
let multiple = [
    [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop as NSNumber,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Joystick as NSNumber
    ], [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop as NSNumber,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_GamePad as NSNumber
    ]] as CFArray

let CommunicationLeft = joyconCommunication()
let CommunicationRight = joyconCommunication()
var DataLeft : joyconData!
var DataRight : joyconData!

enum connectStatus : Int {
    case none = 0
    case right = 1
    case left = 2
    case both = 3
}

var connectionStatus : connectStatus = .none

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBAction func clickQuit(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    @IBOutlet weak var moveSpeedItem: MoveSpeedView!
    
    
    var threadPool : [Thread?] = [nil,nil]//[left,right]
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @objc func startListen(device : IOHIDDevice) {//device
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as! String
        print(name)
        let leftName = "Joy-Con (L)"
        let rightName = "Joy-Con (R)"
        IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
        if name == leftName {
            DataLeft = joyconData(device: device, communicator: CommunicationLeft,side: "Left")
        }
        else if name == rightName {
            DataRight = joyconData(device: device, communicator: CommunicationRight,side: "Right")
        }
        else {
            return
        }
        
    }
    
    let matchingCallback: IOHIDDeviceCallback = {context, result, sender, device in
        print("Match")
        
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as! String
        print(name)
        let myAppdelegate = NSApplication.shared.delegate as! AppDelegate
        let leftName = "Joy-Con (L)"
        let rightName = "Joy-Con (R)"
        if name != leftName && name != rightName {
            return
        }
        
        if name == rightName {
            var threadRight = Thread(target: myAppdelegate, selector: #selector(myAppdelegate.startListen(device:)), object: device)
            myAppdelegate.threadPool[1] = threadRight
            threadRight.start()
            
            if connectionStatus == .none {
                connectionStatus = .right
            }
            if connectionStatus == .left {
                connectionStatus = .both
            }
        }
        else {
            var threadLeft = Thread(target: myAppdelegate, selector: #selector(myAppdelegate.startListen(device:)), object: device)
            myAppdelegate.threadPool[0] = threadLeft
            threadLeft.start()
            
            if connectionStatus == .none {
                connectionStatus = .left
            }
            if connectionStatus == .right {
                connectionStatus = .both
            }
        }
        myAppdelegate.changeStatusIcon()
    }
    
    let removalCallback: IOHIDDeviceCallback = {context, result, sender, device in
        print("Remove")
        let myAppdelegate = NSApplication.shared.delegate as! AppDelegate
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as! String
        let leftName = "Joy-Con (L)"
        let rightName = "Joy-Con (R)"
        if name == rightName {
            if connectionStatus == .both {
                connectionStatus = .left
            }
            if connectionStatus == .right {
                connectionStatus = .none
            }
            myAppdelegate.threadPool[1]?.cancel()
        }
        else {
            if connectionStatus == .both {
                connectionStatus = .right
            }
            if connectionStatus == .left {
                connectionStatus = .none
            }
            myAppdelegate.threadPool[0]?.cancel()
        }
        myAppdelegate.changeStatusIcon()
    }

    func changeStatusIcon() {
        if connectionStatus == .none {
            let icon = NSImage(named: NSImage.Name(rawValue: "StatusIcon"))
            icon?.isTemplate = true
            self.statusItem.image = icon
            self.statusItem.menu = statusMenu
        }
        if connectionStatus == .right {
            let icon = NSImage(named: NSImage.Name(rawValue: "StatusRightIcon"))
            icon?.isTemplate = true
            self.statusItem.image = icon
            self.statusItem.menu = statusMenu
        }
        if connectionStatus == .left {
            let icon = NSImage(named: NSImage.Name(rawValue: "StatusLeftIcon"))
            icon?.isTemplate = true
            self.statusItem.image = icon
            self.statusItem.menu = statusMenu
        }
        if connectionStatus == .both {
            let icon = NSImage(named: NSImage.Name(rawValue: "StatusBothIcon"))
            icon?.isTemplate = true
            self.statusItem.image = icon
            self.statusItem.menu = statusMenu
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let icon = NSImage(named: NSImage.Name(rawValue: "StatusIcon"))
        icon?.isTemplate = true
        self.statusItem.image = icon
        self.statusItem.menu = statusMenu
        //let speedItem = self.statusMenu.item(withTitle: "Speed Item")
        //speedItem?.view = self.moveSpeedItem
        //self.moveSpeedItem.joyconData1 = DataRight
        
        IOHIDManagerSetDeviceMatchingMultiple(manager, multiple)
        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback,nil)
        getPermission()
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, nil)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        CFRunLoopRun()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        //IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        //IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        // Insert code here to tear down your application
    }
}

