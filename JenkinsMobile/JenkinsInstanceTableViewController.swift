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
    var subMenuDelegate: SubMenuDelegate!
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
        
        self.showCredentialsFields = self.jinstance.shouldAuthenticate!.boolValue
        self.syncMgr = SyncManager.sharedInstance;
        self.managedObjectContext = self.syncMgr?.mainMOC
        self.saveChanges = true
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(JenkinsInstanceTableViewController.handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        
        // setting the result view's height contraint's constant to 0 makes the view not
        // take up any space while hidden
        self.testResultViewHeightConstraint.constant = 0
        self.testResultView?.isHidden = true
        self.testResultLabel?.isHidden = true
        
        if (self.jinstance.url == self.syncMgr?.currentJenkinsInstance?.url) {
            self.activeInstance = true
        }
        
        self.initObservers()
        self.setTitle()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(JenkinsInstanceTableViewController.jenkinsInstancePingResponseReceived(_:)), name: NSNotification.Name.JenkinsInstancePingResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(JenkinsInstanceTableViewController.jenkinsInstancePingRequestFailed(_:)), name: NSNotification.Name.JenkinsInstancePingRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(JenkinsInstanceTableViewController.jenkinsInstanceAuthenticateReceived(_:)), name: NSNotification.Name.JenkinsInstanceAuthenticationResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(JenkinsInstanceTableViewController.jenkinsInstanceAuthenticateFailed(_:)), name: NSNotification.Name.JenkinsInstanceAuthenticationRequestFailed, object: nil)
    }
    
    func setTitle() {
        if (self.jinstance.name != nil) {
            self.navigationItem.title = self.jinstance.name
        } else {
            self.navigationItem.title = "Add Jenkins Instance"
        }
    }
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func toggleTestResultsView(_ show: Bool) {
        if (show) {
            self.testResultViewHeightConstraint.constant = 30
        } else {
            self.testResultViewHeightConstraint.constant = 0
        }
        
        UIView.transition(with: self.actionsContainerView!, duration: 0.25, options: UIViewAnimationOptions(),
            animations: {
                self.testResultView?.isHidden = !show
                self.actionsContainerView?.layoutIfNeeded()
                self.testResultLabel?.isHidden = !show
            }, completion: nil)
    }
    
    func updateTestResultsView(_ color: UIColor, message: String, duration: Double, showActivityIndicator: Bool) {
        // Update the results view to green success
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.testResultLabel?.text = message
            self.testResultView?.backgroundColor = color
            self.testActivityIndicator?.isHidden = !showActivityIndicator
            }, completion: nil)
        
        // remove the view after showing it for specified duration
        let delayTime = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.toggleTestResultsView(false)
        }

    }
    
    func stateChanged(_ switchView: KDBSwitch) {
        switch  switchView.switchType! {
        case SwitchViewType.allowInvalidSSL:
            self.jinstance.allowInvalidSSLCertificate = NSNumber(value: switchView.isOn as Bool)
        case SwitchViewType.enabled:
            self.jinstance.enabled = NSNumber(value: switchView.isOn as Bool)
        case SwitchViewType.useAuthentication:
            self.showCredentialsFields = switchView.isOn
            self.jinstance.shouldAuthenticate = NSNumber(value: switchView.isOn as Bool)
            self.tableView.reloadData()
        case SwitchViewType.active:
            self.activeInstance = switchView.isOn
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
    func textFieldValueChanged(_ textField: KDBTextField) {
        self.validate(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.jinstance.managedObjectContext?.undoManager?.beginUndoGrouping()
        let kdbTextField: KDBTextField = textField as! KDBTextField
        let validated = self.validate(textField)

        if (validated && saveChanges!) {
            switch kdbTextField.type! {
            case .name:
                self.jinstance.name = textField.text
            case .url:
                if (self.jinstance.url != nil && self.jinstance.url != "" && self.jinstance.url != textField.text) {
                    urlFieldChanged(textField)
                } else {
                    self.jinstance.url = textField.text
                    self.jinstance.correctURL()
                    textField.text = self.jinstance.url
                }
            case .username:
                self.jinstance.username = textField.text
            case .password:
                self.jinstance.password = textField.text!
            }
        }
       
        self.jinstance.managedObjectContext?.undoManager?.endUndoGrouping()
    }
        
    func urlFieldChanged(_ textField: UITextField) {
        let alert = UIAlertController(title: "Update Server URL", message: "Updating the URL will force a complete re-sync, deleting all previously synced data. Continue?", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            textField.text = self.jinstance.url
        }
        let updateAction = UIAlertAction(title: "Update", style: .destructive) { (action) in
            self.jinstance.url = textField.text
            self.jinstance.correctURL()
            textField.text = self.jinstance.url
        }
        alert.addAction(updateAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func validate(_ textField: UITextField) -> Bool {
        var validated = true
        let kdbTextField: KDBTextField = textField as! KDBTextField
        //var error: NSError? = nil
        var message: NSString? = nil
        
        switch kdbTextField.type! {
        case .name:
            validated = self.jinstance.validateName(kdbTextField.text!, withMessage: &message)
        case .url:
            validated = self.jinstance.validateURL(kdbTextField.text!, withMessage: &message)
        case .username:
            validated = self.jinstance.validateUsername(kdbTextField.text!, withMessage: &message)
        case .password:
            validated = self.jinstance.validatePassword(kdbTextField.text!, withMessage: &message)
        }
        
        markTextField(kdbTextField, valid: validated, message: message)
        
        return validated
    }
    
    func markTextField(_ textField: KDBTextField, valid: Bool, message: NSString?) {
        if (!valid) {
            textField.setInvalidBorder()
            textField.placeholder = message as? String
        } else {
            textField.setNoBorder()
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        var rows = 0;
        switch section {
        case 0: // server info
            rows = 2
        case 1: // authentication
            rows = 1
            if (self.jinstance.shouldAuthenticate!.boolValue) {
                rows = 3
            }
        case 2: // other
            rows = 2
        default:
            rows = 0
        }
        return rows
    }
    
    func configureSwitchCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let switchView = KDBSwitch(frame: CGRect.zero)
        switchView.addTarget(self, action: #selector(JenkinsInstanceTableViewController.stateChanged(_:)), for: UIControlEvents.valueChanged)
        if indexPath.section == 1 {
            cell.textLabel?.text = "Authenticate?"
            switchView.switchType = .useAuthentication
            switchView.setOn(self.jinstance.shouldAuthenticate!.boolValue, animated: false)
        } else {
            if indexPath.row == 0 {
                switchView.switchType = .allowInvalidSSL
                cell.textLabel?.text = "Allow Invalid SSL Certificate?"
                switchView.setOn(self.jinstance.allowInvalidSSLCertificate!.boolValue, animated: false)
            } else {
                switchView.switchType = .active
                cell.textLabel?.text = "Active?"
                switchView.setOn((self.jinstance.url == self.syncMgr?.currentJenkinsInstance?.url), animated: false)
            }
        }
        cell.accessoryView = switchView
    }
    
    func configureTextEntryCell(_ cell: KDBTextFieldTableViewCell, atIndexPath indexPath: IndexPath) {
        var textFieldText: String?
        var textFieldType: TextFieldType?
        var labelText: String?
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                labelText = "Name"
                textFieldText = jinstance.name
                textFieldType = .name
            case 1:
                labelText = "URL"
                textFieldText = jinstance.url
                textFieldType = .url
                cell.textField?.keyboardType = .URL
                cell.textField?.autocapitalizationType = .none
                cell.textField?.autocorrectionType = .no
            default:
                textFieldText = ""
            }
        case 1:
            switch indexPath.row {
            case 1:
                labelText = "Username"
                textFieldText = jinstance.username
                textFieldType = .username
                cell.textField?.autocapitalizationType = .none
                cell.textField?.autocorrectionType = .no
            case 2:
                labelText = "Password"
                if (!jinstance.password.isEmpty) {
                    textFieldText = generateRandomPasswordMask()
                }
                textFieldType = .password
                cell.textField?.isSecureTextEntry = true
                cell.textField?.autocapitalizationType = .none
                cell.textField?.autocorrectionType = .no
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if ((indexPath.section == 1 && indexPath.row == 0) || (indexPath.section == 2)) {
            cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) 
            self.configureSwitchCell(cell, atIndexPath: indexPath)
        } else {
            let tfcell = tableView.dequeueReusableCell(withIdentifier: "TextEntryCell", for: indexPath) as! KDBTextFieldTableViewCell
            self.configureTextEntryCell(tfcell, atIndexPath: indexPath)
            cell = tfcell
        }
        
        return cell
    }
    
    @IBAction func testButtonTapped(_ sender: UIButton) {
        var message: NSString? = nil
        if let url = self.jinstance.url {
            if (self.jinstance.validateURL(url, withMessage: &message)) {
                self.testActivityIndicator?.isHidden = false
                self.testActivityIndicator?.startAnimating()
                self.testResultLabel?.text = "Connecting..."
                self.testResultView?.backgroundColor = UIColor.lightGray
                self.toggleTestResultsView(true)
                
                let requestHandler = KDBJenkinsRequestHandler()
                // test connection
                requestHandler.pingJenkinsInstance(self.jinstance)
            }
        }
    }
    
    // MARK: - Observers
    func jenkinsInstancePingResponseReceived(_ notification: Notification) {
        if (self.jinstance.shouldAuthenticate!.boolValue) {
            let requestHandler = KDBJenkinsRequestHandler()
            // test authentication
            requestHandler.authenticateJenkinsInstance(self.jinstance)
        } else {
            // Update the results view to green success
            self.updateTestResultsView(UIColor.green, message: "\u{2713} Success", duration: 2, showActivityIndicator: false)
        }

    }
    
    func jenkinsInstancePingRequestFailed(_ notification: Notification) {
        self.updateTestResultsView(UIColor.red, message: "Unable to reach server.", duration: 3, showActivityIndicator: false)
    }
    
    func jenkinsInstanceAuthenticateReceived(_ notification: Notification) {
        self.jinstance.authenticated = true
        // Update the results view to green success
        self.updateTestResultsView(UIColor.green, message: "\u{2713} Success", duration: 2, showActivityIndicator: false)
    }
    
    func jenkinsInstanceAuthenticateFailed(_ notification: Notification) {
        self.updateTestResultsView(UIColor.red, message: "Authentication failed.", duration: 3, showActivityIndicator: false)
    }
    
    // MARK: - UIActionSheetDelegate
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            if (self.syncMgr?.currentJenkinsInstance == self.jinstance) {
                self.syncMgr?.currentJenkinsInstance = nil
            }
            self.managedObjectContext?.delete(self.jinstance)
            self.managedObjectContext?.performAndWait({
                self.syncMgr?.saveContext(self.managedObjectContext)
            })
            self.syncMgr?.masterMOC.performAndWait({
                self.syncMgr?.saveContext(self.syncMgr?.masterMOC)
            })
            self.activeInstance = false
            self.saveChanges = true
            self.performSegue(withIdentifier: "jenkinsInstanceDoneSegue", sender: self)
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        self.saveChanges = true
        self.view.window?.endEditing(true)
        var message: NSString? = nil
        
        if (self.jinstance.validate(withMessage: &message)) {
            saveAndClose()
        } else {
            print(message)
            self.toggleTestResultsView(true)
            self.updateTestResultsView(UIColor.red, message: "Invalid values. Please provide all fields.", duration: 3, showActivityIndicator: false)
        }
    }
    
    func saveAndClose() {
        let datamgr = DataManager.sharedInstance
        datamgr.saveContext(datamgr.mainMOC)
        datamgr.masterMOC.performAndWait({
            datamgr.saveContext(datamgr.masterMOC)
        })
        
        do {
            try self.jinstance.managedObjectContext?.obtainPermanentIDs(for: [self.jinstance])
        } catch {
            print("Error obtaining permanet ID for JenkinsInstance")
            abort()
        }
        
        if (self.activeInstance) {
            self.syncMgr?.currentJenkinsInstance = self.jinstance
        } else {
            self.syncMgr?.currentJenkinsInstance = nil
        }
        
        self.performSegue(withIdentifier: "jenkinsInstanceDoneSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier != "jenkinsInstanceDoneSegue") {
            self.saveChanges = false
            self.jinstance.managedObjectContext?.undoManager?.undo()
        }
        
        if (segue.identifier == "jenkinsInstanceDoneSegue") {
            self.subMenuDelegate.revealToggle()
        }
        
        if (segue.identifier == "jenkinsInstanceCancelSegue") {
            if (self.jinstance.objectID.isTemporaryID) {
                let datamgr = DataManager.sharedInstance
                datamgr.mainMOC.delete(self.jinstance)
                datamgr.saveContext(datamgr.mainMOC)
            }
        }
    }
}
