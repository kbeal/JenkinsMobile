//
//  KDBSwitch.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 8/7/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

enum SwitchViewType {
    case useAuthentication
    case allowInvalidSSL
    case enabled
    case active
}

class KDBSwitch: UISwitch {
    var switchType: SwitchViewType?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
