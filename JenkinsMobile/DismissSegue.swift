//
//  DismissSegue.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 7/16/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

class DismissSegue: UIStoryboardSegue {    
    override func perform() {
        let sourceViewController: UIViewController = self.sourceViewController as! UIViewController
        sourceViewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
