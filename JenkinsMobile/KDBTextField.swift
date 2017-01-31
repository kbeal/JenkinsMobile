//
//  KDBTextField.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 8/13/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

enum TextFieldType {
    case name
    case url
    case username
    case password
}

class KDBTextField: UITextField {

    var type: TextFieldType?
    
    func setInvalidBorder() {
        self.layer.cornerRadius = 8.0
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 1.0
    }
    
    func setNoBorder() {
        self.layer.borderColor = UIColor.clear.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
