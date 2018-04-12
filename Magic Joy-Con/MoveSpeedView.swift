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
    
    var joyconData : joyconData!
    var name : String = "Move Speed: "
    var value : Double = 0.5
    
    @IBAction func sliderChanged(_ sender: NSSlider) {
        self.value = sender.doubleValue / sender.maxValue
        if self.joyconData != nil {
            self.joyconData.moveSpeed = self.value
        }
    }
    
    func viewDidLoad() {
        self.speedSlider.doubleValue = 0.5 * self.speedSlider.maxValue
    }
    
}
