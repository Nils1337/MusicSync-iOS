//
//  ArtistsTableViewController.swift
//  MusicSync
//
//  Created by nils on 23.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData

class ArtistCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    var artist: String?
    
    func setData(_ dbResult: NSDictionary) {
        artist = dbResult[SongTable.artistColumnName] as? String
        nameLabel.text = artist
    }
}

class ArtistsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var artists = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(synchronizationFinished), name: NSNotification.Name("SongsSynchronized"), object: nil)
        
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell", for: indexPath) as! ArtistCell

        let result = artists[indexPath.item]
        cell.setData(result)

        return cell
    }
    
    private func loadData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [SongTable.artistColumnName]
        request.returnsDistinctResults = true
        request.sortDescriptors = [NSSortDescriptor(key:SongTable.artistColumnName, ascending: true)]
        artists = try! ctx.fetch(request) as! [NSDictionary]
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let albumsVC = segue.destination as? AlbumsTableViewController {
            if let artistCell = sender as? ArtistCell {
                albumsVC.artist = artistCell.artist
            }
        }
    }
    
    func synchronizationFinished() {
        OperationQueue.main.addOperation {
            self.loadData()
        }
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
