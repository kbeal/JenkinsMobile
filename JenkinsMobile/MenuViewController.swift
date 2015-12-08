//
//  MenuViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 6/23/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var addServerButton: UIButton!
    var managedObjectContext: NSManagedObjectContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.managedObjectContext = SyncManager.sharedInstance.mainMOC
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        return sectionInfo.numberOfObjects
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let jinstance = self.fetchedResultsController.objectAtIndexPath(indexPath) as! JenkinsInstance
        cell.textLabel?.text = jinstance.name
        cell.detailTextLabel?.text = jinstance.url
        
        if let currentJI: JenkinsInstance = SyncManager.sharedInstance.currentJenkinsInstance {
            if ((jinstance.url != nil) && (currentJI.url == jinstance.url)) {
                if (currentJI.shouldAuthenticate!.boolValue) {
                    if ((jinstance.authenticated != nil) && (currentJI.authenticated!.boolValue)) {
                        cell.imageView?.image = StatusCircle.imageForCircle(UIColor.blueColor())
                    } else {
                        cell.imageView?.image = StatusCircle.imageForCircle(UIColor.redColor())
                    }
                } else {
                    cell.imageView?.image = StatusCircle.imageForCircle(UIColor.blueColor())
                }
            } else {
                cell.imageView?.image = StatusCircle.imageForCircle(UIColor.grayColor())
            }
        } else {
            cell.imageView?.image = StatusCircle.imageForCircle(UIColor.grayColor())
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("JenkinsInstanceCell", forIndexPath: indexPath) 
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        let destinationNavController: UINavigationController = segue.destinationViewController as! UINavigationController
        let destination: JenkinsInstanceTableViewController = destinationNavController.topViewController as! JenkinsInstanceTableViewController
        
        if (segue.identifier == "showJenkinsInstance") {
            destination.jinstance = self.fetchedResultsController.objectAtIndexPath(self.tableView.indexPathForSelectedRow!) as! JenkinsInstance
        } else {
            destination.jinstance = JenkinsInstance.createJenkinsInstanceWithValues(nil, inManagedObjectContext: self.managedObjectContext!)
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    var fetchedResultsController: NSFetchedResultsController {
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = self.managedObjectContext!
        
        let entity = NSEntityDescription.entityForName("JenkinsInstance", inManagedObjectContext: managedObjectContext)
        let sort = NSSortDescriptor(key: "name", ascending: true)
        let req = NSFetchRequest()
        req.entity = entity
        req.sortDescriptors = [sort]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: req, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        self._fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return self._fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController?
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            switch type {
            case .Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Update:
                let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
                self.configureCell(cell!, atIndexPath: indexPath!)
                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

}
