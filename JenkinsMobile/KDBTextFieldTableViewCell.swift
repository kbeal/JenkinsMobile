//
//  KDBTextFieldTableViewCell.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 8/27/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

class KDBTextFieldTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textField: KDBTextField?
    @IBOutlet weak var label: UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textLabel?.backgroundColor = UIColor.red
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
