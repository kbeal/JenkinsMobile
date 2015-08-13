//
//  AddServerTableViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 7/16/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

class JenkinsInstanceTableViewController: UITableViewController {
    
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
                switchView.switchType = .Enabled
                cell.textLabel?.text = "Enabled?"
                switchView.setOn(self.jinstance.enabled.boolValue, animated: false)
            }
        }
        //cell.delegate = self
        cell.accessoryView = switchView
    }
    
    func configureTextEntryCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Name"
                cell.detailTextLabel?.text = jinstance.name
            case 1:
                cell.textLabel?.text = "URL"
                cell.detailTextLabel?.text = jinstance.url
            default:
                cell.detailTextLabel?.text = ""
            }
        case 1:
            switch indexPath.row {
            case 1:
                cell.textLabel?.text = "Username"
                cell.detailTextLabel?.text = jinstance.username

            case 2:
                cell.textLabel?.text = "Password"
                cell.detailTextLabel?.text = generateRandomPasswordMask()
            default:
                cell.detailTextLabel?.text = ""
            }
        default:
            println("Invalid section")
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if ((indexPath.section == 1 && indexPath.row == 0) || (indexPath.section == 2)) {
            cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! UITableViewCell
            self.configureSwitchCell(cell, atIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("TextEntryCell", forIndexPath: indexPath) as! UITableViewCell
            self.configureTextEntryCell(cell, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "jenkinsInstanceDoneSegue") {
            self.syncMgr?.saveContext(self.managedObjectContext)
        }
    }
}
