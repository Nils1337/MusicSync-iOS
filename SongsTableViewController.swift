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
    weak var download: URLSessionDownloadTask?
    
    func setData(_ song: Song) {
        self.song = song
        titleLabel.text = song.title
    }
}

class LocalSongCell: SongCell {
    let gesture = UILongPressGestureRecognizer()
}

class DownloadingSongCell: SongCell {
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

}

class RemoteSongCell: SongCell {
    
}

class SongsTableViewController: UITableViewController, DownloadDelegate {
    
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
        
        DownloadManager.shared.delegate = self

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
        
        switch (song.downloadStatus) {
            case .Remote:
                cell = tableView.dequeueReusableCell(withIdentifier: "remoteSongCell", for: indexPath) as! SongCell
                cell.setEditing(false, animated: true)
                break
            case .Downloading:
                cell = tableView.dequeueReusableCell(withIdentifier: "downloadingSongCell", for: indexPath) as! SongCell
                let downloadCell = cell as! DownloadingSongCell
                downloadCell.loadingIndicator.startAnimating()
                break
            case .Local:
                let localCell = tableView.dequeueReusableCell(withIdentifier: "localSongCell", for: indexPath) as! LocalSongCell
                /*localCell.gesture.addTarget(self, action: #selector(localCellPressedLong))
                localCell.gestureRecognizers = []
                localCell.gestureRecognizers!.append(localCell.gesture)*/
                cell = localCell
                break
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
            
            guard let song = cell.song else {
                print("cell has no song!")
                return
            }
            
            guard let server = appDelegate.server else {
                print("no server for downloading available!")
                return
            }
            
            if !appDelegate.isWifiConnected() {
                let alert = UIAlertController(title: "Connection Error", message: "You are not connected to Wifi!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                    alertAction in
                    DownloadManager.shared.addDownload(server: server, song: song)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                DownloadManager.shared.addDownload(server: server, song: song)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
        }
        else if cell is LocalSongCell {
            tabBarController?.selectedIndex = 3
        }
    }
    
    func localCellPressedLong(_ sender: UILongPressGestureRecognizer) {
        self.tableView.setEditing(!true, animated: true)
    }
    
    func downloadFinished(_ download: Download) {
        appDelegate.saveContext()
        OperationQueue.main.addOperation {
            self.loadData()
        }
    }
    
    func update() {
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let cell = tableView.cellForRow(at: indexPath)
        return cell is LocalSongCell
    }
    

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! LocalSongCell
            
            //TODO delete file
            cell.song!.downloadStatus = .Remote
            
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: cell.song!.filename!)
            }
            catch {
                print(error.localizedDescription)
            }
            
            appDelegate.saveContext()
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

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
