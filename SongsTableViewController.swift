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

class LocalSongCell: SongCell {
    
}

class RemoteSongCell: SongCell {
    
}

class SongsTableViewController: UITableViewController {
    
    var artist: String?  {
        didSet(oldValue) {
            updateTitle()
        }
    }
    var album: String?  {
        didSet(oldValue) {
            updateTitle()
        }
    }
    var playlist: String?
    var songlist: [String]?
    var library: Library? {
        didSet(oldValue) {
            updateTitle()
        }
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var fetchedController: NSFetchedResultsController<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        library = appDelegate.library
        updateTitle()
        loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notifications.libraryChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notifications.synchronizedNotification, object: nil)
        
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
        
        guard let object = self.fetchedController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without managed object")
        }
        
        guard let song = object as? Song else {
            fatalError("Object fetched from database is not a song!")
        }
        
        var cell: SongCell
        
        if (song.downloaded == 0) {
            cell = tableView.dequeueReusableCell(withIdentifier: "remoteSongCell", for: indexPath) as! SongCell
        
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "localSongCell", for: indexPath) as! SongCell
        }
        
        cell.setData(song)
        
        return cell
    }
    
    private func updateTitle() {
        var title = "No Library Selected"
        if (library != nil) {
            if (album == nil && artist == nil) {
                title = "All Songs"
            }
            else if (album == nil && artist != nil) {
                title = "All Songs of \(artist!)"
            }
            else if (album != nil && artist != nil) {
                title = album!
            }
        }
        self.navigationItem.title = title
    }
    
    private func loadData() {
        
        guard let library = library else {
            self.fetchedController = nil
            self.tableView.reloadData()
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        request.resultType = .managedObjectResultType
        request.sortDescriptors = [NSSortDescriptor(key:SongTable.titleColumnName, ascending: true)]
        
        if let artist = artist {
            if let album = album {
                request.predicate = NSPredicate(format: "\(SongTable.artistColumnName) = %@ AND \(SongTable.albumColumnName) = %@ AND \(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", artist, album, library.id!)
            }
            else {
                request.predicate = NSPredicate(format: "\(SongTable.artistColumnName) = %@ AND \(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", artist, library.id!)
            }
        }
        else {
            request.predicate = NSPredicate(format: "\(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", library.id!)
        }

        fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: ctx, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedController!.performFetch()
        }
        catch {
            fatalError("Failed to fetch entities: \(error)")
        }
        self.tableView.reloadData()
    }

    func reload(_ notification: NSNotification) {
        if notification.name == Notifications.libraryChangedNotification {
            library = appDelegate.library
        }
        OperationQueue.main.addOperation {
            self.loadData()
        }
    }
    
    @IBAction func drawerButtonClicked(_ sender: Any) {
        (self.tabBarController as! TabViewController).toggleDrawer()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SongCell
        if cell is RemoteSongCell {
            cell.song!.downloaded = 1
            appDelegate.saveContext()
            loadData()
        }
        else {
            tabBarController?.selectedIndex = 3
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

    @IBAction func unwindToServers(segue: UIStoryboardSegue) {
        
    }
    
}
