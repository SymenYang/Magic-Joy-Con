#  Magic Joy-Con
## Introduction
#### With Magic Joy-Con you can control your mac by it's joystick,buttons,and motion.Also you can customize the control profile by editing code.
---
## Usage
#### Run Magic Joy-Con.app
#### And make sure your joycon are named "Joy-Con (L)" and "Joy-Con (R)", which is the default names of Joy-Cons
---
## Customize
### Customize buttons
#### In the file JoyConClass.swift, change the code in defaultOption function.Right Joy-Con will call the function defaultOptionRight,and left Joy-Con will call the function defaultOptionLeft.
#### Register button callback with function 

    self.registerButtonFunction(onWhat : onSituation, key : buttonNum, function : @escaping () -> ()) 

#### onSituation is an enum type with four values : 

    enum onSituation : Int {
        case Down = 0
        case Up = 1
        case Hold = 2
        case Release = 3
    }

#### **Hold** means hold the button (LOW signal),**Release** means not press the button (HIGH signal),**Down** means the falling edge,**Up** means the raising edge
#### buttonNum is an enum type with 22 values(left & right Joy-Con have 22 keys total) :

    enum buttonNum : Int {
        //Left Joy-Con
        case A = 0
        case B = 1
        case X = 2
        case Y = 3
        case R = 4
        case add = 5
        case R_SR = 6
        case R_SL = 7
        case R_Stick = 8
        case home = 9
        //Right Joy-Con
        case ZR = 10
        case up = 11
        case down = 12
        case left = 13
        case right = 14
        case L = 15
        case minus = 16
        case L_SR = 17
        case L_SL = 18
        case L_Stick = 19
        case capture = 20
        case ZL = 21
    }

### Customize joystick and motion data
#### Register LstickAction,RstickAction,accGyroAction to deal those data.
### Some basic actions are written in MacOperator.swift. Check the code for using them.
## Default config
#### Hold ZR and wave Joy-Con to move mouse.
#### Move right joystick(fast mode) or left joystick(slow mode) can move mouse too.
#### Press button *A* for LeftMouseClick.
#### Press *R* for RightMouseClick.Hold *X* or *B* for MouseScroll.
#### Press button *Y* as press right-option(In my mac is to call mission control).
#### Press *L_SR* or *L_SL* as press command  + ',' or '.'(In my mac is to switch desktops).
#### Arrow keys are mapping to the arrow key in Mac.Others are not mapped.
#### Can change the move speed in status bar menu.This will change the *movespeed* in class joyconData.Check the code for more details.
## Thanks
#### [Nintendo_Switch_Reverse_Engineering](https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering/)
#### [switch_joy_con_as_mouse_for_macos](https://github.com/mnogu/switch_joy_con_as_mouse_for_macos)
