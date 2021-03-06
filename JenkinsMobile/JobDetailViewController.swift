//
//  JobDetailViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 1/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import UIKit
import SpriteKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class JobDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var job: Job?
    var lastbuild: Build?
    var permalinks = [[String:AnyObject?]]()
    var lastBuildSyncTimer: Timer?
    var latestBuilds: [AnyObject]?
    var upstreamProjectsSectionIndex: Int?
    var downstreamProjectsSectionIndex: Int?
    var jobHasACS: Bool = false // indicates whether this job has active configurations
    var visible: Bool = false // determines whether this VC is visible
    let syncMgr = SyncManager.sharedInstance
    @IBOutlet weak var statusBallView: UIImageView?
    @IBOutlet weak var healthImageView: UIImageView?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var currentBuildNumberLabel: UILabel?
    @IBOutlet weak var currentBuildDateLabel: UILabel?
    @IBOutlet weak var emptyPermalinksView: UIView?
    @IBOutlet weak var emptyViewImageTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var viewModeSwitcher: UISegmentedControl?
    @IBOutlet weak var descriptionView: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emptyViewImageTopConstraint?.constant = emptyViewImageTopConstraintConstant()
        
        if self.job != nil {
            //observe changes to model
            NotificationCenter.default.addObserver(self, selector: #selector(JobDetailViewController.handleDataModelChange(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: syncMgr.masterMOC)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // determine if job has active configurations
        if let acs = self.job!.activeConfigurations as? [[String: AnyObject]] {
            if acs.count > 0 {
                self.jobHasACS = true
            }
        }
        setNavTitleAndButton()
        self.updateDisplay()
        self.configureViewModeSwitcher()
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.visible = true
        // sync this job with latest from server
        syncMgr.syncJob(self.job!)
        // sync details for latest builds
        syncMgr.syncLatestBuildsForJob(self.job!, numberOfBuilds: 10)
        // select first segment of view mode switcher
        self.viewModeSwitcher?.selectedSegmentIndex = 0
        self.lastbuild = self.getLatestBuild()
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // stop build status timer, set to nil
        self.lastBuildSyncTimer?.invalidate()
        self.lastBuildSyncTimer = nil
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.visible = false
        super.viewDidDisappear(animated)
    }
    
    // updates last segment to 'Configurations' if this job has active configs
    func configureViewModeSwitcher() {
        if self.jobHasACS {
            self.viewModeSwitcher?.setTitle("Configurations", forSegmentAt: 2)
        } else {
            self.viewModeSwitcher?.setTitle("Description", forSegmentAt: 2)
        }
    }
    
    func setTimer(_ interval: Double) {
        if (self.visible) {
            self.lastBuildSyncTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(lastBuildSyncTimerTick), userInfo: nil, repeats: true)
            self.lastBuildSyncTimerTick()
        }
    }
    
    func getLatestBuild() -> Build? {
        var build: Build?
        // fetch the last build
        if let jobLastBuild: [String:AnyObject] = self.job?.lastBuild as? [String:AnyObject],
            let lastBuildURL: String = jobLastBuild[BuildURLKey] as? String {
                build = Build.fetch(withURL: lastBuildURL, in: syncMgr.mainMOC)
        }
        return build
    }
    
    func fetchLatestBuilds() {
        self.latestBuilds = self.job!.fetchLatestBuilds(30) as [AnyObject]?
    }
    
    func handleDataModelChange(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let updatedObjects = userInfo[NSUpdatedObjectsKey] as! NSSet as! Set<NSManagedObject>
            for obj: NSManagedObject in updatedObjects {
                if obj.objectID == self.job?.objectID {
                    self.watchedJobChanged()
                    self.updateDisplay()
                }
                
                if obj.objectID == self.lastbuild?.objectID {
                    self.updateDisplay()
                }
            }
        }
    }
    
    func watchedJobChanged() {
        DispatchQueue.main.async(execute: {
            // if job's last build changed make sure it gets synced up
            if let jobLastBuild: [String:AnyObject] = self.job!.lastBuild as? [String:AnyObject] {
                if let jobLastBuildNum: Int = jobLastBuild[BuildNumberKey] as? Int {
                    if jobLastBuildNum != self.lastbuild?.number?.intValue {
                        self.syncMgr.syncLatestBuildsForJob(self.job!, numberOfBuilds: 5)
                        self.lastbuild = self.getLatestBuild()
                    }
                }
            }
        })
    }
    
    func setNavTitleAndButton() {
        if job != nil {
            self.navigationItem.leftBarButtonItem?.image = UIImage(named: "logo.png")?.withRenderingMode(.alwaysOriginal)
            self.navigationItem.title = job!.name
        }
    }
    
    func updateDisplay() {
        DispatchQueue.main.async(execute: {
            if self.job != nil {
                self.updateLastBuildLabels()
                self.updateJobStatusIcon()
                self.updateBuildProgressView()
                self.updateContentModeView()
                self.updateHealthImageView()
            }
        })
    }
    
    func lastBuildSyncTimerTick() {
        print("job detail tick")
        // query build progress
        if self.lastbuild != nil {
            self.syncMgr.syncProgressForBuild(self.lastbuild!, jenkinsInstance: self.job!.rel_Job_JenkinsInstance!)
        }
        
        if !self.visible {
            self.lastBuildSyncTimer?.invalidate()
            self.lastBuildSyncTimer = nil
        }
    }
    
    func getHealthImageName() -> String? {
        var healthImageName: String?
        if let healthReports = self.job!.healthReport as? [Dictionary<String, AnyObject>] {
            if healthReports.count > 0 {
                let firstReport: Dictionary<String, AnyObject> = healthReports[0]
                if let healthIconClassName = firstReport[JobHealthReportIconClassNameKey] as? String {
                    healthImageName = healthIconClassName.replacingOccurrences(of: "icon-", with: "")
                }
            }
        }
        return healthImageName
    }
    
    func updateHealthImageView() {
        if let imageName = self.getHealthImageName() {
            self.healthImageView?.image = UIImage(named: imageName)
        }
    }
    
    func updateBuildProgressView() {
        if self.lastbuild != nil {
            //print("********** updating build progress view for build \(self.lastbuild?.number.integerValue)")
            //print("********** the build building is \(self.lastbuild?.building.integerValue)")
            if (self.lastbuild!.building?.boolValue)! {
                self.updateProgressViewObservedProgress()
                
                // create and start build status timer
                if self.lastBuildSyncTimer == nil {
                    self.setTimer(self.syncIntervalForBuild((self.lastbuild!.estimatedDuration?.doubleValue)!))
                }
                
                // show progress view
                //print("********** showing progress view: \(self.progressView?.progress)")
                self.progressView?.isHidden = false

            } else {
                //print("********** hiding progress view")
                // hide progress view
                self.progressView?.isHidden = true
                // stop build status timer, set to nil
                self.lastBuildSyncTimer?.invalidate()
                self.lastBuildSyncTimer = nil
            }
        }
    }
    
    func updateProgressViewObservedProgress() {
        // if the progressview is already observing progress of a build
        if let observedBuildProgress: BuildProgress = self.progressView?.observedProgress as? BuildProgress {
            // ensure that its the latest build
            if observedBuildProgress.buildToWatch.objectID != self.lastbuild!.objectID {
                // observe project of last build
                self.progressView?.observedProgress = BuildProgress(build: self.lastbuild!)
            }
        } else {
            // observe project of last build
            self.progressView?.observedProgress = BuildProgress(build: self.lastbuild!)
        }
    }
    
    // updates the lower area of view that contains
    // permalinks table, all build history table, job description, etc
    // based on user's choice
    @IBAction func updateContentModeView() {
        DispatchQueue.main.async(execute: {
            switch self.viewModeSwitcher!.selectedSegmentIndex {
            case 0:
                // status, or permalinks mode
                self.updatePermalinks()
                self.updateBuildsTable()
            case 1:
                // history mode (all builds)
                self.updateBuildsTable()
            case 2:
                if self.jobHasACS {
                    self.updateBuildsTable()
                } else {
                    // job description mode
                    self.showDescriptionView()
                }
            default:
                break
            }
        })
    }
    
    func showBuildsTable() {
        self.emptyPermalinksView?.isHidden = true
        self.tableView?.isHidden = false
        self.descriptionView!.isHidden = true
    }
    
    func showEmptyBuildsTable() {
        self.emptyPermalinksView?.isHidden = false
        self.tableView?.isHidden = true
        self.descriptionView!.isHidden = true
    }
    
    func showDescriptionView() {
        self.updateJobDescriptionView()
        self.emptyPermalinksView?.isHidden = true
        self.tableView?.isHidden = true
        self.descriptionView!.isHidden = false
    }
    
    func updateBuildsTable() {
        switch self.viewModeSwitcher!.selectedSegmentIndex {
        case 0:
            // status, or permalinks mode
            if self.permalinks.count > 0 {
                self.showBuildsTable()
                self.tableView?.reloadData()
            } else {
                self.showEmptyBuildsTable()
            }
        case 1:
            // history mode (all builds)
            if self.job!.rel_Job_Builds?.count > 0 {
                // TODO - implement spinner?
                self.fetchLatestBuilds()
                self.showBuildsTable()
                self.tableView?.reloadData()
            } else {
                self.showEmptyBuildsTable()
            }
        case 2:
            if self.jobHasACS {
                if let acs = self.job!.activeConfigurations as? [[String: AnyObject]] {
                    if acs.count > 0 {
                        self.tableView?.reloadData()
                    } else {
                        self.showEmptyBuildsTable()
                    }
                }
            } else {
                self.showEmptyBuildsTable()
            }
        default:
            self.showEmptyBuildsTable()
        }
    }
    
    func updateJobDescriptionView() {
        if let desc = self.job!.job_description {
            do {
                let attrdesc = try NSAttributedString(data: desc.data(using: String.Encoding.utf8)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8], documentAttributes: nil)
                self.descriptionView?.attributedText = attrdesc
            } catch {
                self.descriptionView?.text = ""
            }
        }
    }
    
    func updateLastBuildLabels() {
        if let lastBuild = self.job!.lastBuild as? NSDictionary {
            if let lastBuildNumber = lastBuild[BuildNumberKey] as? Int {
                self.currentBuildNumberLabel?.text = "# " + String(lastBuildNumber)
            }
            if let lastBuildTimestamp = lastBuild[BuildTimestampKey] as? Double {
                self.currentBuildDateLabel?.text = DateHelper.dateStringFromTimestamp(lastBuildTimestamp)
            }
        }
    }
    
    func updateJobStatusIcon() {
        if self.lastbuild != nil {
            if (self.lastbuild!.building?.boolValue)! {
                self.startImageViewAnimation(self.statusBallView!, color: self.job!.color!)
            } else {
                self.stopImageViewAnimation(self.statusBallView!, color: self.job!.color!)
            }
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
    
    // Updates array of permalink builds that is used
    // as datasource for permalinks table view
    func updatePermalinks() {
        self.permalinks.removeAll(keepingCapacity: true)
        if self.job!.lastBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastBuild! as Optional<AnyObject>])
        }
        
        if self.job?.lastStableBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last stable build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastStableBuild! as Optional<AnyObject>])
        }
        
        if self.job?.lastSuccessfulBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last successful build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastSuccessfulBuild! as Optional<AnyObject>])
        }
        
        if self.job?.lastFailedBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last failed build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastFailedBuild! as Optional<AnyObject>])
        }
        
        if self.job?.lastUnsuccessfulBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last unsuccessful build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastUnsuccessfulBuild! as Optional<AnyObject>])
        }
        
        if self.job?.lastUnstableBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last unstable build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastUnstableBuild! as Optional<AnyObject>])
        }
        
        if self.job?.lastCompletedBuild != nil {
            self.permalinks.append([JobPermalinkNameKey:"Last completed build" as Optional<AnyObject>,JobPermalinkKey: self.job!.lastCompletedBuild! as Optional<AnyObject>])
        }
        
        if self.permalinks.count > 0 {
            self.permalinks.append([JobPermalinkNameKey:"All builds" as Optional<AnyObject>,JobPermalinkKey:nil])
        }
    }
    
    func emptyViewImageTopConstraintConstant() -> CGFloat {
        var constraint = 40
        
        if IS_IPHONE_4_OR_LESS {
            constraint = 0
        }
        
        return CGFloat(constraint)
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
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // http://stackoverflow.com/a/25877725
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        // Doesn't seem to be needed. Keep for posterity
        //cell.preservesSuperviewLayoutMargins = false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // if the status view mode is selected
        if self.viewModeSwitcher?.selectedSegmentIndex == 0 {
            // if the selected row is the last row in the permalinks section
            if ( (indexPath.section == 0) && (indexPath.row == (self.tableView!.numberOfRows(inSection: indexPath.section) - 1))) {
                // goto the all builds view
                print("all builds")
            } else {
                // else goto build detail
                self.performSegue(withIdentifier: "showBuildDetail", sender: self)
            }
        } else {
            // else goto build detail
            self.performSegue(withIdentifier: "showBuildDetail", sender: self)
        }
        self.tableView?.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        var numSections: Int = 1
        
        if self.viewModeSwitcher?.selectedSegmentIndex == 0 {
            if let upprojs = self.job!.upstreamProjects {
                if (upprojs as AnyObject).count() > 0 {
                    self.upstreamProjectsSectionIndex = numSections
                    numSections += 1
                }
            }
            
            if let downprojs = self.job!.downstreamProjects {
                if (downprojs as AnyObject).count() > 0 {
                    self.downstreamProjectsSectionIndex = numSections
                    numSections += 1
                }
            }
        }
        return numSections
    }
    
    func countRows() -> Int {
        var numRows: Int = 0
        if let modeSwitcher = self.viewModeSwitcher {
            switch modeSwitcher.selectedSegmentIndex {
            case 0:
                // status, or permalinks mode
                numRows = self.permalinks.count
            case 1:
                // history mode (all builds)
                if self.latestBuilds != nil {
                    numRows = self.latestBuilds!.count
                }
            case 2:
                if self.jobHasACS {
                    // active configurations count
                    if let acs = self.job!.activeConfigurations as? [[String: AnyObject]] {
                        numRows = acs.count
                    }
                }
                // job description mode
                break
            default:
                numRows = 0
            }
        }
        return numRows
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int = 0
        
        if section == 0 {
            numRows = self.countRows()
        } else {
            if let upindex = self.upstreamProjectsSectionIndex {
                if section == upindex {
                    if let upprojs = self.job!.upstreamProjects {
                        numRows = (upprojs as AnyObject).count()
                    }
                }
            }
            
            if let downindex = self.downstreamProjectsSectionIndex {
                if section == downindex {
                    if let downprojs = self.job!.downstreamProjects {
                        numRows = (downprojs as AnyObject).count()
                    }
                }
            }
        }
        
        return numRows
    }
    
    func configureConfigurationCell(_ cell: UITableViewCell, configuration: [String: AnyObject]) {
        cell.detailTextLabel?.text = ""
        
        if let configname = configuration[ActiveConfigurationNameKey] as? String {
            cell.textLabel?.text = configname
        }
        
        if let configcolor = configuration[ActiveConfigurationColorKey] as? String {
            let normcolor = Job.getNormalizedColor(configcolor)
            let building = Build.colorIsBuilding(normcolor)
            if (building) {
                self.startImageViewAnimation(cell.imageView!, color: normcolor)
            } else {
                self.stopImageViewAnimation(cell.imageView!, color: normcolor)
            }
        }
    }
    
    func configureRelatedProjectCell(_ cell: UITableViewCell, relatedProject: [String: AnyObject]) {
        cell.detailTextLabel?.text = ""
        
        if let projname = relatedProject[JobNameKey] as? String {
            cell.textLabel?.text = projname
        }
        
        if let projcolor = relatedProject[JobColorKey] as? String {
            let normcolor = Job.getNormalizedColor(projcolor)
            let building = Build.colorIsBuilding(normcolor)
            if (building) {
                self.startImageViewAnimation(cell.imageView!, color: normcolor);
            } else {
                self.stopImageViewAnimation(cell.imageView!, color: normcolor);
            }
        }

    }
    
    func configurePermalinkCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let permalinkwrapper: [String: AnyObject?] = self.permalinks[indexPath.row]
        cell.textLabel?.text = permalinkwrapper[JobPermalinkNameKey] as? String
        cell.detailTextLabel?.text = "View all builds for this Job"
        
        if let healthImageName = self.getHealthImageName() {
            cell.imageView?.image = UIImage(named: healthImageName)
        }
        
        if let permalink = permalinkwrapper[JobPermalinkKey] as! [String: AnyObject]? {
            //var color: String? = Build.getColorForResult(permalink[BuildResultKey] as? String)
            var timestamp = permalink[BuildTimestampKey] as! Double
            
            if let building: Bool = permalink[BuildBuildingKey] as? Bool {
                if building {
                    self.startImageViewAnimation(cell.imageView!, color: self.job!.color!)
                    if let lastbuild = self.lastbuild {
                        timestamp = (lastbuild.timestamp?.timeIntervalSince1970)! * 1000
                    }
                } else {
                    let color: String? = Build.getColorForResult(permalink[BuildResultKey] as? String)
                    if color != nil {
                        self.stopImageViewAnimation(cell.imageView!, color: color!)
                    } else {
                        cell.imageView?.image = nil
                    }
                }
            } else {
                cell.imageView?.image = nil
            }
            
            //if color != nil {
                //cell.imageView?.image = UIImage(named: color! + "-status-100")
            //}
            let number = String(permalink[BuildNumberKey] as! Int)
            cell.textLabel?.text = (cell.textLabel?.text)! + " (#" + number + ")"
            if let relativeTimeStr = DateHelper.relativeDateStringFromTimestamp(timestamp) {
                cell.detailTextLabel?.text = relativeTimeStr + " ago"
            }
        }
    }
    
    func configureBuildHistoryCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        if let latest = self.latestBuilds,
            let build = latest[indexPath.row] as? Build {
                if let color = Build.getColorForResult(build.result) {
                    cell.imageView?.image = UIImage(named: color + "-status-100")
                }
                cell.textLabel?.text = "#" + (build.number?.stringValue)! + " - " + DateHelper.dateStringFromTimestamp(((build.timestamp?.timeIntervalSince1970)! * 1000))
                cell.detailTextLabel?.text = "" 
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var name: String = ""
        if self.viewModeSwitcher?.selectedSegmentIndex == 0 {
            if section == 0 {
                name = "Permalinks"
            } else {
                if let upindex = self.upstreamProjectsSectionIndex {
                    if section == upindex {
                        name = "Upstream Projects"
                    }
                }
                
                if let downindex = self.downstreamProjectsSectionIndex {
                    if section == downindex {
                        name = "Downstream Projects"
                    }
                }
            }
        }
        return name
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView!.dequeueReusableCell(withIdentifier: "BuildCell", for: indexPath)
        if indexPath.section == 0 {
            if let modeSwitcher = self.viewModeSwitcher {
                switch modeSwitcher.selectedSegmentIndex {
                case 0:
                    // status, or permalinks mode
                    self.configurePermalinkCell(cell, indexPath: indexPath)
                case 1:
                    // history mode (all builds)
                    self.configureBuildHistoryCell(cell, indexPath: indexPath)
                    break
                case 2:
                    // active configurations
                    if let acs = self.job!.activeConfigurations as? [[String: AnyObject]] {
                        self.configureConfigurationCell(cell, configuration: acs[indexPath.row])
                    }
                    break
                default:
                    // status, or permalinks mode
                    self.configurePermalinkCell(cell, indexPath: indexPath)
                }
            }
        } else {
            if let upindex = self.upstreamProjectsSectionIndex {
                if indexPath.section == upindex {
                    if let upprojs = self.job!.upstreamProjects as? [[String: AnyObject]] {
                        self.configureRelatedProjectCell(cell, relatedProject: upprojs[indexPath.row])
                    }
                }
            }
            
            if let downindex = self.downstreamProjectsSectionIndex {
                if indexPath.section == downindex {
                    if let downprojs = self.job!.downstreamProjects as? [[String: AnyObject]] {
                        self.configureRelatedProjectCell(cell, relatedProject: downprojs[indexPath.row])
                    }
                }
            }
        }

        return cell
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var perform = false
        if identifier == "showBuildDetail" {
            // only segue to build details if we in the right view mode
            // and table section
            let index: IndexPath = (self.tableView?.indexPathForSelectedRow)!
            if index.section == 0 {
                if let modeSwitcher = self.viewModeSwitcher {
                    if modeSwitcher.selectedSegmentIndex < 2 {
                        perform = true
                    }
                }
            }
        }
        return perform
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBuildDetail" {
            let buildDetailNavController = segue.destination as! UINavigationController
            let buildDetailVC = buildDetailNavController.topViewController as! BuildDetailViewController
            let index: IndexPath = (self.tableView?.indexPathForSelectedRow)!

            if index.section == 0 {
                // switch on selected segment
                if let modeSwitcher = self.viewModeSwitcher {
                    switch modeSwitcher.selectedSegmentIndex {
                    // status, permalinks mode
                    case 0:
                        let permalinkwrapper: [String: AnyObject?] = self.permalinks[index.row]
                        if let permalink = permalinkwrapper[JobPermalinkKey] as! [String: AnyObject]? {
                            let buildURL: String = permalink[BuildURLKey] as! String
                            let build = Build.fetch(withURL: buildURL, in: syncMgr.mainMOC)
                            buildDetailVC.build = build
                        }
                    //history mode
                    case 1:
                        if let latest = self.latestBuilds,
                            let build = latest[index.row] as? Build {
                            buildDetailVC.build = build
                        }
                    default:
                        buildDetailVC.build = nil
                    }
                }
            } else {
                // upstream or downstream
            }
            //buildDetailVC.build = self.fetchedResultsController.objectAtIndexPath(self.tableView.indexPathForSelectedRow!) as? Job
        }
    }
}
