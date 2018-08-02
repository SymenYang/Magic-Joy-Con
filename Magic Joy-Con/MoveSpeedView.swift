//
//  MoveSpeedView.swift
//  Magic Joy-Con
//
//  Created by SymenYang on 2018/4/11.
//  Copyright © 2018年 SymenYang. All rights reserved.
//

import Foundation
import Cocoa

class MoveSpeedView : NSView {
    @IBOutlet weak var speedSlider: NSSlider!
    
    var joyconData1 : joyconData!
    var joyconData2 : joyconData!
    var name : String = "Move Speed: "
    var value : Double = 0.5
    
    @IBAction func sliderChanged(_ sender: NSSlider) {
        self.value = sender.doubleValue / sender.maxValue
        if self.joyconData1 != nil {
            self.joyconData1.moveSpeed = self.value
        }
        if self.joyconData2 != nil {
            self.joyconData2.moveSpeed = self.value
        }
    }
    
    func viewDidLoad() {
        self.speedSlider.doubleValue = 0.5 * self.speedSlider.maxValue
    }
    
}
