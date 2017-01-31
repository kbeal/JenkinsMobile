//
//  JobsTableViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 1/16/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import UIKit

class JobsTableViewController: KDBJenkinsTableViewController, NSFetchedResultsControllerDelegate {
    
    var parentView: View?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavTitleAndButton()
        
        if self.parentView != nil {
            self.syncMgr.syncView(self.parentView!)
        }
    }
    
    func setNavTitleAndButton() {
        if self.parentView != nil {
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.title = self.parentView!.name
        } else {
            self.navigationItem.leftBarButtonItem?.image = UIImage(named: "logo.png")?.withRenderingMode(.alwaysOriginal)
            self.navigationItem.title = "All Jobs"
        }
    }
    
    
//    #pragma mark - Table view delegate
//    -(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//    {
//    // Remove seperator inset
//    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
//    [cell setSeparatorInset:UIEdgeInsetsZero];
//    }
//    
//    // Explictly set your cell's layout margins
//    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
//    [cell setLayoutMargins:UIEdgeInsetsZero];
//    }
//    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (self.fetchedResultsController.sections?.count)!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let job = self.fetchedResultsController.object(at: indexPath) as! Job
        cell.textLabel?.text = job.name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "JobCell", for: indexPath)
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showJobDetail" {
            let jobDetailNavController = segue.destination as! UINavigationController
            let jobDetailTVC = jobDetailNavController.topViewController as! JobDetailViewController
            jobDetailTVC.job = self.fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!) as? Job
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = self.managedObjectContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Job", in: managedObjectContext)
        let sort = NSSortDescriptor(key: "name", ascending: true)
        let req = NSFetchRequest<NSFetchRequestResult>()
        req.entity = entity
        req.sortDescriptors = [sort]
        
        if self.parentView != nil {
            req.predicate = NSPredicate(format: "rel_Job_Views contains[cd] %@", self.parentView!)
        }
        
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

}
