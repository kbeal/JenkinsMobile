//
//  BuildDetailViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 5/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import UIKit

class BuildDetailViewController: UIViewController , UITableViewDataSource, UITableViewDelegate {
    
    let syncMgr = SyncManager.sharedInstance
    var build: Build?
    var buildSyncTimer: NSTimer?
    @IBOutlet weak var statusBallView: UIImageView?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var emptyTableView: UIView?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var viewModeSwitcher: UISegmentedControl?
    @IBOutlet weak var buildNumberLabel: UILabel?
    @IBOutlet weak var buildDateLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.build != nil {
            //observe changes to model
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BuildDetailViewController.handleDataModelChange(_:)), name: NSManagedObjectContextDidSaveNotification, object: syncMgr.masterMOC)
            // sync this job with latest from server
            syncMgr.syncBuild(self.build!)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        print("****** build detail view will disappear")
        // stop build status timer, set to nil
        self.buildSyncTimer?.invalidate()
        self.buildSyncTimer = nil
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleDataModelChange(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let updatedObjects = userInfo[NSUpdatedObjectsKey] as! NSSet as! Set<NSManagedObject>
            for obj: NSManagedObject in updatedObjects {
                if obj.objectID == self.build?.objectID {
                    self.updateDisplay()
                }
            }
        }
    }
    
    func updateDisplay() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.build != nil {
                self.updateLabels()
                self.updateJobStatusIcon()
                self.updateBuildProgressView()
            }
        })
    }
    
    func updateLabels() {
        self.buildNumberLabel?.text = "# " + String(self.build!.number)
        self.buildDateLabel?.text = DateHelper.dateStringFromDate(self.build!.timestamp)
    }
    
    func updateJobStatusIcon() {
        if self.build!.building.boolValue {
            self.startImageViewAnimation(self.statusBallView!, color: self.build!.rel_Build_Job.color!)
        } else {
            self.stopImageViewAnimation(self.statusBallView!, color: Build.getColorForResult(self.build!.result)!)
        }
    }
    
    func updateBuildProgressView() {
        if self.build!.building.boolValue {
            self.updateProgressViewObservedProgress()
            
            // create and start build status timer
            if self.buildSyncTimer == nil {
                self.setTimer(self.syncIntervalForBuild(self.build!.estimatedDuration.doubleValue))
            }
            
            // show progress view
            self.progressView?.hidden = false
            
        } else {
            // hide progress view
            self.progressView?.hidden = true
            // stop build status timer, set to nil
            self.buildSyncTimer?.invalidate()
            self.buildSyncTimer = nil
        }
    }
    
    func setTimer(interval: Double) {
        self.buildSyncTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(buildSyncTimerTick), userInfo: nil, repeats: true)
        self.buildSyncTimerTick()
    }
    
    // determines how often to pool a build for completion.
    // the longer the esimatedDuration the less often it is polled
    func syncIntervalForBuild(estimatedDuration: Double) -> Double {
        //        let durationSec = estimatedDuration / 1000
        //        // if the estimated duration is 9 minutes is less
        //        if durationSec <= 540 {
        //            return (durationSec * 0.5)
        //        } else {
        //            return (durationSec * 0.01)
        //        }
        return 1.0
    }
    
    func buildSyncTimerTick() {
        // query build progress
        if self.build != nil {
            self.syncMgr.syncProgressForBuild(self.build!, jenkinsInstance: self.build!.rel_Build_Job.rel_Job_JenkinsInstance!)
        }
    }
    
    func updateProgressViewObservedProgress() {
        // if the progressview is already observing progress of a build
        if let observedBuildProgress: BuildProgress = self.progressView?.observedProgress as? BuildProgress {
            // ensure that its the latest build
            if observedBuildProgress.buildToWatch.objectID != self.build!.objectID {
                // observe project of last build
                self.progressView?.observedProgress = BuildProgress(build: self.build!)
            }
        } else {
            // observe project of last build
            self.progressView?.observedProgress = BuildProgress(build: self.build!)
        }
    }
    
    func startImageViewAnimation(imageView: UIImageView, color: String) {
        imageView.animationImages = self.animationImages(color)
        imageView.animationDuration = StatusBallAnimationDuration
        imageView.startAnimating()
    }
    
    func stopImageViewAnimation(imageView: UIImageView, color: String) {
        imageView.image = UIImage(named: color + "-status-100")
        imageView.stopAnimating()
        imageView.animationImages = nil
    }
    
    func animationImages(color: String) -> [UIImage] {
        return [
            UIImage(named: color + "-status-100")!,
            UIImage(named: color + "-status-80")!,
            UIImage(named: color + "-status-60")!,
            UIImage(named: color + "-status-40")!,
            UIImage(named: color + "-status-20")!,
            UIImage(named: color + "-status-40")!,
            UIImage(named: color + "-status-60")!,
            UIImage(named: color + "-status-80")!]
    }
    
    // MARK: - Table view delegate
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // http://stackoverflow.com/a/25877725
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        // Doesn't seem to be needed. Keep for posterity
        //cell.preservesSuperviewLayoutMargins = false
    }

    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var numSections: Int = 1
        return numSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int = 2
        return numRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView!.dequeueReusableCellWithIdentifier("BuildCell", forIndexPath: indexPath)
        
        if ( indexPath.row == 0 ) {
            if let actions = self.build!.actions as? [[String: AnyObject]] {
                for action: [String: AnyObject] in actions {
                    if let causes = action["causes"] as? [[String: AnyObject]] {
                        let firstcause = causes[0]
                        if let shortDesc = firstcause["shortDescription"] as? String {
                            cell.textLabel?.text = shortDesc
                        }
                    }
                }
            }
        } else {
            
        }
        
        return cell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
