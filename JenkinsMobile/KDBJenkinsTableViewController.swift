//
//  KDBJenkinsViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 1/16/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import UIKit

class KDBJenkinsTableViewController: UITableViewController {
    let syncMgr = SyncManager.sharedInstance
    let managedObjectContext = SyncManager.sharedInstance.mainMOC
    @IBOutlet weak var sidebarButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setSplitViewDelegate()
        self.initRevealToggle()
    }
    
    func initRevealToggle() {
        if self.revealViewController() != nil {
            sidebarButton!.target = self.revealViewController()
            sidebarButton!.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    func setSplitViewDelegate() {
        let appDelegate = UIApplication.sharedApplication().delegate as! KDBAppDelegate
        let revealController = self.revealViewController()
        let splitController = revealController.frontViewController as! UISplitViewController
        splitController.delegate = appDelegate
    }
}
