//
//  RecentActivityViewController.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/30/17.
//  Copyright © 2017 Kyle Beal. All rights reserved.
//

import UIKit

class RecentActivityViewController: KDBJenkinsTableViewController, NSFetchedResultsControllerDelegate {

    override func viewWillAppear(_ animated: Bool) {
        setNavTitleAndButton()
        super.viewWillAppear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setNavTitleAndButton() {
        self.navigationItem.leftBarButtonItem?.image = UIImage(named: "logo.png")?.withRenderingMode(.alwaysOriginal)
        self.navigationItem.title = "Recent Activity"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (self.fetchedResultsController.sections?.count)!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let build = self.fetchedResultsController.object(at: indexPath) as! Build
        let buildNumber = String(describing: build.number);
        cell.textLabel?.text = build.rel_Build_Job!.name! + ": " + buildNumber;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "BuildCell", for: indexPath)
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Fetched Results Controller Delegate
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = self.managedObjectContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Build", in: managedObjectContext)
        let sort = NSSortDescriptor(key: "number", ascending: true)
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

}
