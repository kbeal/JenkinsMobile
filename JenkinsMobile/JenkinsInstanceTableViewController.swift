//
//  AddServerTableViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 7/16/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

class JenkinsInstanceTableViewController: UITableViewController, UITextFieldDelegate {
    
    var jinstance: JenkinsInstance!
    var managedObjectContext: NSManagedObjectContext?
    var showCredentialsFields: Bool?
    var syncMgr: SyncManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showCredentialsFields = self.jinstance.shouldAuthenticate.boolValue
        self.syncMgr = SyncManager.sharedInstance;
        self.managedObjectContext = self.syncMgr?.mainMOC
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func stateChanged(switchView: KDBSwitch) {
        switch  switchView.switchType! {
        case SwitchViewType.AllowInvalidSSL:
            self.jinstance.allowInvalidSSLCertificate = NSNumber(bool: switchView.on)
        case SwitchViewType.Enabled:
            self.jinstance.enabled = NSNumber(bool: switchView.on)
        case SwitchViewType.UseAuthentication:
            self.showCredentialsFields = switchView.on
            self.jinstance.shouldAuthenticate = NSNumber(bool: switchView.on)
            self.tableView.reloadData()
        default:
            println("invalid SwitchTableViewCellType")
            abort()
        }
    }
    
    func generateRandomPasswordMask() -> String {
        let lowerBound: Int = 6
        let upperBound: Int = 12
        let strlen: Int = lowerBound + Int(arc4random()) % (upperBound - lowerBound)
        var randPasswordMask = "•"
        
        for i in 1...strlen {
            randPasswordMask += "•"
        }
        return randPasswordMask
    }
    
    // MARK: - Text Field Delegate
    func textFieldValueChanged(textField: KDBTextField) {
        self.validate(textField)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.jinstance.managedObjectContext?.undoManager?.beginUndoGrouping()
        let kdbTextField: KDBTextField = textField as! KDBTextField
        let validated = self.validate(textField)
        
        if (validated) {
            switch kdbTextField.type! {
            case .Name:
                self.jinstance.name = textField.text
            case .URL:
                self.jinstance.url = textField.text
            case .Username:
                self.jinstance.username = textField.text
            case .Password:
                self.jinstance.password = textField.text
            default:
                println("invalid textfieldtype")
                abort()
            }
        }
       
        self.jinstance.managedObjectContext?.undoManager?.endUndoGrouping()
    }
    
    func validate(textField: UITextField) -> Bool {
        var validated = true
        let kdbTextField: KDBTextField = textField as! KDBTextField
        var error: NSError? = nil
        var message: NSString? = nil
        
        switch kdbTextField.type! {
        case .Name:
            validated = self.jinstance.validateName(kdbTextField.text, withMessage: &message)
        case .URL:
            validated = self.jinstance.validateURL(kdbTextField.text, withMessage: &message)
        default:
            validated = true
        }
        
        if (!validated) {
            kdbTextField.setInvalidBorder()
            kdbTextField.placeholder = message as? String
        } else {
            kdbTextField.setNoBorder()
        }
        
        return validated
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        var rows = 0;
        switch section {
        case 0: // server info
            rows = 2
        case 1: // authentication
            rows = 1
            if (self.jinstance.shouldAuthenticate.boolValue) {
                rows = 3
            }
        case 2: // other
            rows = 2
        default:
            rows = 0
        }
        return rows
    }
    
    func configureSwitchCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let switchView = KDBSwitch(frame: CGRectZero)
        if indexPath.section == 1 {
            cell.textLabel?.text = "Authenticate?"
            switchView.addTarget(self, action: "stateChanged:", forControlEvents: UIControlEvents.ValueChanged)
            switchView.switchType = .UseAuthentication
            switchView.setOn(self.jinstance.shouldAuthenticate.boolValue, animated: false)
        } else {
            if indexPath.row == 0 {
                switchView.switchType = .AllowInvalidSSL
                cell.textLabel?.text = "Allow Invalid SSL Certificate?"
                switchView.setOn(self.jinstance.allowInvalidSSLCertificate.boolValue, animated: false)
            } else {
                switchView.switchType = .Active
                cell.textLabel?.text = "Active?"
                switchView.setOn(self.jinstance.enabled.boolValue, animated: false)
            }
        }
        cell.accessoryView = switchView
    }
    
    func configureTextEntryCell(cell: KDBTextFieldTableViewCell, atIndexPath indexPath: NSIndexPath) {
        var textFieldText: String?
        var textFieldType: TextFieldType?
        var labelText: String?
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                labelText = "Name"
                textFieldText = jinstance.name
                textFieldType = .Name
            case 1:
                labelText = "URL"
                textFieldText = jinstance.url
                textFieldType = .URL
            default:
                textFieldText = ""
            }
        case 1:
            switch indexPath.row {
            case 1:
                labelText = "Username"
                textFieldText = jinstance.username
                textFieldType = .Username
            case 2:
                labelText = "Password"
                if (jinstance.password != nil) {
                    textFieldText = generateRandomPasswordMask()
                }
                textFieldType = .Password
            default:
                textFieldText = ""
            }
        default:
            println("Invalid section")
            abort()
        }

        cell.textField?.delegate = self
        cell.textField?.text = textFieldText
        cell.textField?.type = textFieldType!
        cell.label?.text = labelText
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if ((indexPath.section == 1 && indexPath.row == 0) || (indexPath.section == 2)) {
            cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! UITableViewCell
            self.configureSwitchCell(cell, atIndexPath: indexPath)
        } else {
            let tfcell = tableView.dequeueReusableCellWithIdentifier("TextEntryCell", forIndexPath: indexPath) as! KDBTextFieldTableViewCell
            self.configureTextEntryCell(tfcell, atIndexPath: indexPath)
            cell = tfcell
        }
        
        return cell
    }
    
    // MARK: - UIActionSheetDelegate

    @IBAction func deleteButtonTapped(sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
            self.managedObjectContext?.deleteObject(self.jinstance)
            self.performSegueWithIdentifier("jenkinsInstanceDoneSegue", sender: self)
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "jenkinsInstanceDoneSegue") {
            //self.syncMgr?.saveContext(self.managedObjectContext)
            self.syncMgr?.saveMainContext()
        } else {
            self.jinstance.managedObjectContext?.undoManager?.undo()
        }
    }
}
