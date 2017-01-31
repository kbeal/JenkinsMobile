//
//  StatusCircle.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 8/29/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import Foundation

let height: CGFloat = 15
let width: CGFloat = 15
let canvasSize: CGSize = CGSize(width: width, height: height)

class StatusCircle {
    
    static func imageForCircle(_ color: UIColor) -> UIImage {
        // create the context
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0)
        //let context = UIGraphicsGetCurrentContext()
        
        // setup the circle size
        let circleRect: CGRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        
        // Draw the Circle
        let path = UIBezierPath(ovalIn: circleRect)
        color.setFill()
        path.fill()
        
        // return Image
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
