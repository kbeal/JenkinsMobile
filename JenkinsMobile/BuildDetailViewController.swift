//
//  BuildDetailViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 5/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import UIKit

class BuildDetailViewController: UIViewController , UITableViewDataSource, UITableViewDelegate {
    
    var build: Build?
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
            self.updateLabels()
            self.updateJobStatusIcon()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        var numRows: Int = 0
        return numRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView!.dequeueReusableCellWithIdentifier("BuildCell", forIndexPath: indexPath)        
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
