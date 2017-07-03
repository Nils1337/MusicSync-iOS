//
//  SongsTableViewController.swift
//  MusicSync
//
//  Created by nils on 23.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData

class SongCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    var song: Song?
    
    func setData(_ song: Song) {
        self.song = song
        titleLabel.text = song.title
    }
}

class SongsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var artist: String?
    var album: String?
    var playlist: String?
    var songlist: [String]?
    
    var fetchedController: NSFetchedResultsController<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = artist
        loadData()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongCell
        
        guard let object = self.fetchedController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without managed object")
        }
        
        let result = object as! Song
        
        cell.setData(result)
        
        return cell
    }
    
    private func loadData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        request.resultType = .managedObjectResultType
        request.sortDescriptors = [NSSortDescriptor(key:SongTable.titleColumnName, ascending: true)]
        
        if let art = artist {
            if let alb = album {
                request.predicate = NSPredicate(format: SongTable.artistColumnName + " = %@ AND " + SongTable.albumColumnName + " = %@", art, alb)
            }
            else {
                request.predicate = NSPredicate(format: SongTable.artistColumnName + " = %@", art)
            }
        }

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
