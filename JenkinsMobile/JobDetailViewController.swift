//
//  JobDetailViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 1/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import UIKit
import SpriteKit

class JobDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var job: Job?
    @IBOutlet weak var descriptionWebView: UIWebView?
    @IBOutlet weak var statusBallContainerView: SKView?
    @IBOutlet weak var healthButton: UIButton?
    @IBOutlet weak var tableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavTitleAndButton()
        self.updateDisplay()
        
    }
    
    func setNavTitleAndButton() {
        if job != nil {
            self.navigationItem.leftBarButtonItem?.image = UIImage(named: "logo.png")?.imageWithRenderingMode(.AlwaysOriginal)
            self.navigationItem.title = job!.name
        }
    }
    
    func updateDisplay() {
        if self.job != nil {
            if self.descriptionWebView != nil && self.job!.job_description != nil{
                self.descriptionWebView?.loadHTMLString((self.job?.job_description)!, baseURL: nil)
            }
            self.descriptionWebView?.loadHTMLString("<html><h3>Performs the following:</h3><ol><li>Checkout</li><li>Build</li></ol></html>", baseURL: nil)
            //updateJobStatusIcon()
        }
    }
    
    func updateJobStatusIcon() {
        // create and configure the scene
        let scene = KDBBallScene(size: self.statusBallContainerView!.bounds.size, andColor: self.job!.absoluteColor(), withAnimation: false)
        scene.scaleMode = SKSceneScaleMode.AspectFill
        
        // present the scene
        self.statusBallContainerView?.presentScene(scene)
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {

    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCellWithIdentifier("BuildCell", forIndexPath: indexPath)
        return cell
    }
}
