//
//  MenuViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 6/23/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController, NSFetchedResultsControllerDelegate, SubMenuDelegate {
    
    @IBOutlet weak var addServerButton: UIButton!
    var managedObjectContext: NSManagedObjectContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.managedObjectContext = SyncManager.sharedInstance.mainMOC
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        return sectionInfo.numberOfObjects
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let jinstance = self.fetchedResultsController.object(at: indexPath) as! JenkinsInstance
        cell.textLabel?.text = jinstance.name
        cell.detailTextLabel?.text = jinstance.url
        
        if let currentJI: JenkinsInstance = SyncManager.sharedInstance.currentJenkinsInstance {
            if ((jinstance.url != nil) && (currentJI.url == jinstance.url)) {
                if (currentJI.shouldAuthenticate!.boolValue) {
                    if ((jinstance.authenticated != nil) && (currentJI.authenticated!.boolValue)) {
                        cell.imageView?.image = StatusCircle.imageForCircle(UIColor.blue)
                    } else {
                        cell.imageView?.image = StatusCircle.imageForCircle(UIColor.red)
                    }
                } else {
                    cell.imageView?.image = StatusCircle.imageForCircle(UIColor.blue)
                }
            } else {
                cell.imageView?.image = StatusCircle.imageForCircle(UIColor.gray)
            }
        } else {
            cell.imageView?.image = StatusCircle.imageForCircle(UIColor.gray)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JenkinsInstanceCell", for: indexPath) 
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        let destinationNavController: UINavigationController = segue.destination as! UINavigationController
        let destination: JenkinsInstanceTableViewController = destinationNavController.topViewController as! JenkinsInstanceTableViewController
        
        if (segue.identifier == "showJenkinsInstance") {
            destination.jinstance = self.fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!) as! JenkinsInstance
        } else {
            destination.jinstance = JenkinsInstance.createJenkinsInstance(withValues: nil, in: self.managedObjectContext!)
        }
        destination.subMenuDelegate = self
    }
    
    // MARK: - SubMenu Delegate
    func revealToggle() {
        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds) + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            let revealVC = self.revealViewController()
            revealVC?.revealToggle(animated: true)
        }
    }

    // MARK: - Fetched Results Controller Delegate
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = self.managedObjectContext!
        
        let entity = NSEntityDescription.entity(forEntityName: "JenkinsInstance", in: managedObjectContext)
        let sort = NSSortDescriptor(key: "name", ascending: true)
        let req = NSFetchRequest<NSFetchRequestResult>()
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
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange object: Any, at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                self.tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
            case .update:
                let cell = self.tableView.cellForRow(at: indexPath!)
                self.configureCell(cell!, atIndexPath: indexPath!)
                self.tableView.reloadRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            case .move:
                self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
                self.tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
            case .delete:
                self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

}
