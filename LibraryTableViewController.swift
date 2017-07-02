//
//  LibraryTableViewController.swift
//  MusicSync
//
//  Created by nils on 28.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData

class LibraryCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    var library: Library?
    
    func setData(_ library: Library) {
        self.library = library
        nameLabel.text = library.name
    }
}

class LibraryTableViewController: UITableViewController {

    var fetchedController: NSFetchedResultsController<NSFetchRequestResult>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()

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
     let cell = tableView.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath) as! LibraryCell
     
     guard let object = self.fetchedController?.object(at: indexPath) else {
        fatalError("Attempt to configure cell without managed object")
     }
     
     let result = object as! Library
     cell.setData(result)
     
     return cell
    }
 
    private func loadData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
        request.resultType = .managedObjectResultType
        let s1 = NSSortDescriptor(key: LibraryTable.serverColumnName, ascending: true)
        let s2 = NSSortDescriptor(key:LibraryTable.nameColumnName, ascending: true)
        request.sortDescriptors = [s1, s2]
        fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: ctx, sectionNameKeyPath: LibraryTable.serverColumnName + "." + ServerTable.nameColumnName, cacheName: nil)
        do {
            try fetchedController!.performFetch()
        }
        catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedController?.sections?[section]
        return sectionInfo?.name
    }
    
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
