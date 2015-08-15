//
//  KDBTextField.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 8/13/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

enum TextFieldType {
    case Name
    case URL
    case Username
    case Password
}

class KDBTextField: UITextField {

    var type: TextFieldType

    init (type: TextFieldType, text: String?, delegate: UITextFieldDelegate) {
        self.type = type
        super.init(frame: CGRect())
        self.tag = 3;
        self.text = text
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.textAlignment = NSTextAlignment.Right
        self.delegate = delegate
        
        if (self.type == .Password) {
            self.secureTextEntry = true
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
