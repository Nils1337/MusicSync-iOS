//
//  ServersTableViewController.swift
//  MusicSync
//
//  Created by nils on 25.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData

class ServerCell: UITableViewCell {
    var server: Server?
    
    func setData(_ server: Server) {
        self.server = server
        textLabel?.text = server.name
    }
}

class ServersTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchedController: NSFetchedResultsController<NSFetchRequestResult>?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddButtonPressed))
        
        fetchedController?.delegate = self
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let frc = fetchedController {
            return frc.sections!.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchedController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "serverCell", for: indexPath) as! ServerCell
        
        guard let object = self.fetchedController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without managed object")
        }
        
        let result = object as! Server
        cell.setData(result)
        
        return cell
    }
    
    private func loadData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Server")
        request.resultType = .managedObjectResultType
        request.sortDescriptors = [NSSortDescriptor(key:ServerTable.nameColumnName, ascending: true)]
        fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: ctx, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedController!.performFetch()
        }
        catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
    
    func onEditButtonPressed() {
        self.tableView.setEditing(true, animated: true)
    }
    
    func onAddButtonPressed() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ServerDetailViewController")
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ServerDetailViewController {
            if let sender = sender as? ServerCell {
                vc.server = sender.server
            }
        }
    }
    
    
    @IBAction func unwindToServers(segue: UIStoryboardSegue) {
        if let vc = segue.source as? ServerDetailViewController {
            
            var server = vc.server
            var adding = false
            if server == nil {
                let ctx = appDelegate.dataStack.mainContext
                server = NSEntityDescription.insertNewObject(forEntityName: "Server", into: ctx) as? Server
                adding = true
            }
            
            server!.name = vc.nameField.text
            server!.url = vc.addressField.text
            server!.port = Int16(vc.portField.text!)!
            
            appDelegate.saveContext()
            if adding {
                NotificationCenter.default.post(name: Notifications.serverAddedNotification, object: server)
            }
            appDelegate.synchronize(with: server!)
        }
    }
    

}
