//: Playground - noun: a place where people can play

import UIKit
import XCPlayground
var str = "Hello, playground"

let view = UIView(frame: CGRectMake(0, 0, 500, 500))
XCPShowView("", view)

let len = view.bounds.height
let gl = CAGradientLayer()
gl.frame = CGRectMake(0, len/2, len, len/2)
gl.colors = [ UIColor.clearColor().CGColor, UIColor.blackColor().CGColor ]
gl.locations = [ 0.0, 1.0 ]

view.layer.addSublayer(gl)