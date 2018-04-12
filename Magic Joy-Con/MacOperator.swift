//
//  MacOperator.swift
//  Magic Joy-Con
//
//  Created by SymenYang on 2018/4/11.
//  Copyright © 2018年 SymenYang. All rights reserved.
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
        keyDown?.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
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
