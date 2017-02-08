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
    var buildSyncTimer: Timer?
    lazy var changes: [Dictionary<String, Any>] = {
        var chgs = [Dictionary<String, Any>]()
        if let cs: [String: Any] = self.build!.changeset as? [String : Any] {
            chgs = cs["items"] as! [Dictionary<String, Any>]
        }
        return chgs
    }()
    
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
            NotificationCenter.default.addObserver(self, selector: #selector(BuildDetailViewController.handleDataModelChange(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: syncMgr.masterMOC)
            // sync this job with latest from server
            syncMgr.syncBuild(self.build!)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
    
    func handleDataModelChange(_ notification: Notification) {
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
        DispatchQueue.main.async(execute: {
            if self.build != nil {
                self.updateLabels()
                self.updateJobStatusIcon()
                self.updateBuildProgressView()
            }
        })
    }
    
    func updateLabels() {
        self.buildNumberLabel?.text = "# " + String(describing: self.build!.number)
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
            self.progressView?.isHidden = false
            
        } else {
            // hide progress view
            self.progressView?.isHidden = true
            // stop build status timer, set to nil
            self.buildSyncTimer?.invalidate()
            self.buildSyncTimer = nil
        }
    }
    
    // updates the lower area of view that contains
    // permalinks table, all build history table, job description, etc
    // based on user's choice
    @IBAction func updateContentModeView() {
        DispatchQueue.main.async(execute: {
            switch self.viewModeSwitcher!.selectedSegmentIndex {
            case 0:
                // build info. SHA ID and trigger
                self.showTable()
            case 1:
                // changes. SCM changesets
                self.showTable()
            case 2:
                // console.
                print("3")
            default:
                break
            }
        })
    }
    
    func setTimer(_ interval: Double) {
        self.buildSyncTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(buildSyncTimerTick), userInfo: nil, repeats: true)
        self.buildSyncTimerTick()
    }
    
    // determines how often to pool a build for completion.
    // the longer the esimatedDuration the less often it is polled
    func syncIntervalForBuild(_ estimatedDuration: Double) -> Double {
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
    
    func startImageViewAnimation(_ imageView: UIImageView, color: String) {
        imageView.animationImages = self.animationImages(color)
        imageView.animationDuration = StatusBallAnimationDuration
        imageView.startAnimating()
    }
    
    func stopImageViewAnimation(_ imageView: UIImageView, color: String) {
        imageView.image = UIImage(named: color + "-status-100")
        imageView.stopAnimating()
        imageView.animationImages = nil
    }
    
    func animationImages(_ color: String) -> [UIImage] {
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
    
    func showTable() {
        self.tableView?.reloadData()
        self.tableView?.isHidden = false
        //self.consoleView!.isHidden = true
    }
    
    func hideTable() {
        self.tableView?.isHidden = true
        //self.consoleView?.isHidden = false
    }
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // http://stackoverflow.com/a/25877725
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        // Doesn't seem to be needed. Keep for posterity
        //cell.preservesSuperviewLayoutMargins = false
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        let numSections: Int = 1
        return numSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int = 0
        
        if let modeSwitcher = self.viewModeSwitcher {
            switch modeSwitcher.selectedSegmentIndex {
            case 0:
                // info mode
                numRows = 2
            case 1:
                // build changes
                numRows = self.changes.count
                break
            default:
                numRows = 0
            }
        }
        return numRows
    }
    
    func configureBuildInfoCell(cell: UITableViewCell, indexPath: IndexPath) {
        var labelTxt: String = ""
        var detailLableTxt: String = ""
        //trigger (causes)
        if ( indexPath.row == 0 ) {
            if let actions = self.build!.actions as? [[String: AnyObject]] {
                for action: [String: AnyObject] in actions {
                    if let causes = action["causes"] as? [[String: AnyObject]] {
                        let firstcause = causes[0]
                        if let shortDesc = firstcause["shortDescription"] as? String {
                            labelTxt = shortDesc
                            cell.imageView?.image = UIImage(named:"orange-square")
                        }
                    }
                }
            }
        } else { // SHA ID
            if let actions = self.build!.actions as? [[String: AnyObject]] {
                for action: [String: AnyObject] in actions {
                    if let lastrev = action["lastBuiltRevision"] as? [String: AnyObject],
                        let branch = lastrev["branch"] as? [[String:AnyObject]],
                        let sha1 = branch[0]["SHA1"] as? String,
                        let name = branch[0]["name"] as? String {
                        labelTxt = "Revision: " + String(sha1.characters.prefix(10))
                        detailLableTxt = name
                        cell.imageView?.image = UIImage(named: "git-logo")
                    }
                }
            }
        }
        
        cell.textLabel?.text = labelTxt
        cell.detailTextLabel?.text = detailLableTxt
    }
    
    func configureBuildChangesCell(cell: UITableViewCell, indexPath: IndexPath) {
        var labelTxt: String = ""
        var detailLableTxt: String = ""
        
        let change = self.changes[indexPath.row]
        labelTxt = change["msg"] as! String
        
        let timestamp = change["timestamp"] as! Double
        let dateStr = DateHelper.dateStringFromTimestamp(timestamp)
        let author = change["author"] as! [String: String]
        let commitID = change["commitId"] as! String
        let commitIDShort = String(commitID.characters.prefix(12))
        detailLableTxt = dateStr + " - " + author["fullName"]! + " - " + commitIDShort
        
        cell.textLabel?.text = labelTxt
        cell.detailTextLabel?.text = detailLableTxt
        cell.imageView?.image = nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView!.dequeueReusableCell(withIdentifier: "BuildCell", for: indexPath)
        
        if let modeSwitcher = self.viewModeSwitcher {
            switch modeSwitcher.selectedSegmentIndex {
            case 0:
                // info mode
                self.configureBuildInfoCell(cell: cell, indexPath: indexPath)
            case 1:
                // build changes
                self.configureBuildChangesCell(cell: cell, indexPath: indexPath)
                break
            default:
                // info mode
                self.configureBuildInfoCell(cell: cell, indexPath: indexPath)
            }
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
