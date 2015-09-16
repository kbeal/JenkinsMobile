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
    var saveChanges: Bool?
    var testingConnection: Bool?
    var activeInstance: Bool = false
    @IBOutlet weak var testResultLabel: UILabel?
    @IBOutlet weak var testResultView: UIView?
    @IBOutlet weak var testResultViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionsContainerView: UIView?
    @IBOutlet weak var testActivityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showCredentialsFields = self.jinstance.shouldAuthenticate.boolValue
        self.syncMgr = SyncManager.sharedInstance;
        self.managedObjectContext = self.syncMgr?.mainMOC
        self.saveChanges = true
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        
        // setting the result view's height contraint's constant to 0 makes the view not
        // take up any space while hidden
        self.testResultViewHeightConstraint.constant = 0
        self.testResultView?.hidden = true
        self.testResultLabel?.hidden = true
        
        if (self.jinstance.url == self.syncMgr?.currentJenkinsInstance?.url) {
            self.activeInstance = true
        }
        
        self.initObservers()
        self.setTitle()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.window?.endEditing(true)
        if (saveChanges!.boolValue) {
            let datamgr = DataManager.sharedInstance
            datamgr.saveMainContext()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstancePingResponseReceived:"), name: JenkinsInstancePingResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstancePingRequestFailed:"), name: JenkinsInstancePingRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceAuthenticateReceived:"), name: JenkinsInstanceAuthenticationResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceAuthenticateFailed:"), name: JenkinsInstanceAuthenticationRequestFailedNotification, object: nil)
    }
    
    func setTitle() {
        if (self.jinstance.name != nil) {
            self.navigationItem.title = self.jinstance.name
        } else {
            self.navigationItem.title = "Add Jenkins Instance"
        }
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func toggleTestResultsView(show: Bool) {
        if (show.boolValue) {
            self.testResultViewHeightConstraint.constant = 30
        } else {
            self.testResultViewHeightConstraint.constant = 0
        }
        
        UIView.transitionWithView(self.actionsContainerView!, duration: 0.25, options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.testResultView?.hidden = !show
                self.actionsContainerView?.layoutIfNeeded()
                self.testResultLabel?.hidden = !show
            }, completion: nil)
    }
    
    func updateTestResultsView(color: UIColor, message: String, duration: Double, showActivityIndicator: Bool) {
        // Update the results view to green success
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.testResultLabel?.text = message
            self.testResultView?.backgroundColor = color
            self.testActivityIndicator?.hidden = !showActivityIndicator
            }, completion: nil)
        
        // remove the view after showing it for specified duration
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.toggleTestResultsView(false)
        }

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
        case SwitchViewType.Active:
            self.activeInstance = switchView.on.boolValue
        default:
            print("invalid SwitchTableViewCellType")
            abort()
        }
    }
    
    func generateRandomPasswordMask() -> String {
        let lowerBound: Int = 6
        let upperBound: Int = 12
        let strlen: Int = lowerBound + Int(arc4random()) % (upperBound - lowerBound)
        var randPasswordMask = "•"
        
        for _ in 1...strlen {
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

        if (validated && saveChanges!.boolValue) {
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
                print("invalid textfieldtype")
                abort()
            }
        }
       
        self.jinstance.managedObjectContext?.undoManager?.endUndoGrouping()
    }
    
    func validate(textField: UITextField) -> Bool {
        var validated = true
        let kdbTextField: KDBTextField = textField as! KDBTextField
        //var error: NSError? = nil
        var message: NSString? = nil
        
        switch kdbTextField.type! {
        case .Name:
            validated = self.jinstance.validateName(kdbTextField.text, withMessage: &message)
        case .URL:
            validated = self.jinstance.validateURL(kdbTextField.text, withMessage: &message)
        case .Username:
            validated = self.jinstance.validateUsername(kdbTextField.text, withMessage: &message)
        case .Password:
            validated = self.jinstance.validatePassword(kdbTextField.text, withMessage: &message)
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
        switchView.addTarget(self, action: "stateChanged:", forControlEvents: UIControlEvents.ValueChanged)
        if indexPath.section == 1 {
            cell.textLabel?.text = "Authenticate?"
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
                switchView.setOn((self.jinstance.url == self.syncMgr?.currentJenkinsInstance?.url), animated: false)
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
                cell.textField?.keyboardType = .URL
                cell.textField?.autocapitalizationType = .None
                cell.textField?.autocorrectionType = .No
            default:
                textFieldText = ""
            }
        case 1:
            switch indexPath.row {
            case 1:
                labelText = "Username"
                textFieldText = jinstance.username
                textFieldType = .Username
                cell.textField?.autocapitalizationType = .None
                cell.textField?.autocorrectionType = .No
            case 2:
                labelText = "Password"
                if (jinstance.password != nil) {
                    textFieldText = generateRandomPasswordMask()
                }
                textFieldType = .Password
                cell.textField?.secureTextEntry = true
                cell.textField?.autocapitalizationType = .None
                cell.textField?.autocorrectionType = .No
            default:
                textFieldText = ""
            }
        default:
            print("Invalid section")
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
            cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) 
            self.configureSwitchCell(cell, atIndexPath: indexPath)
        } else {
            let tfcell = tableView.dequeueReusableCellWithIdentifier("TextEntryCell", forIndexPath: indexPath) as! KDBTextFieldTableViewCell
            self.configureTextEntryCell(tfcell, atIndexPath: indexPath)
            cell = tfcell
        }
        
        return cell
    }
    
    @IBAction func testButtonTapped(sender: UIButton) {
        self.testActivityIndicator?.hidden = false
        self.testActivityIndicator?.startAnimating()
        self.testResultLabel?.text = "Connecting..."
        self.testResultView?.backgroundColor = UIColor.lightGrayColor()
        self.toggleTestResultsView(true)
        
        let requestHandler = KDBJenkinsRequestHandler()
        // test connection
        requestHandler.pingJenkinsInstance(self.jinstance)
    }
    
    // MARK: - Observers
    func jenkinsInstancePingResponseReceived(notification: NSNotification) {
        if (self.jinstance.shouldAuthenticate.boolValue) {
            let requestHandler = KDBJenkinsRequestHandler()
            // test authentication
            requestHandler.authenticateJenkinsInstance(self.jinstance)
        } else {
            // Update the results view to green success
            self.updateTestResultsView(UIColor.greenColor(), message: "\u{2713} Success", duration: 2, showActivityIndicator: false)
        }

    }
    
    func jenkinsInstancePingRequestFailed(notification: NSNotification) {
        self.updateTestResultsView(UIColor.redColor(), message: "Unable to reach server.", duration: 3, showActivityIndicator: false)
    }
    
    func jenkinsInstanceAuthenticateReceived(notification: NSNotification) {
        // Update the results view to green success
        self.updateTestResultsView(UIColor.greenColor(), message: "\u{2713} Success", duration: 2, showActivityIndicator: false)
    }
    
    func jenkinsInstanceAuthenticateFailed(notification: NSNotification) {
        self.updateTestResultsView(UIColor.redColor(), message: "Authentication failed.", duration: 3, showActivityIndicator: false)
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
            self.saveChanges = true
            if (self.activeInstance.boolValue) {
                self.syncMgr?.currentJenkinsInstance = self.jinstance
            } else {
                self.syncMgr?.currentJenkinsInstance = nil
            }
        } else {
            self.saveChanges = false
            self.jinstance.managedObjectContext?.undoManager?.undo()
        }
    }
}
