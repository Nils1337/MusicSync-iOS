//
//  ArtistsTableViewController.swift
//  MusicSync
//
//  Created by nils on 23.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData
import CocoaLumberjack

class ArtistCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var countView: UILabel!
    
    var artist: String?
    
    func setData(_ dbResult: NSDictionary,_ metadata: Metadata) {
        artist = dbResult[SongTable.artistColumnName] as? String
        nameLabel.text = artist
        
        if let picture = metadata.picture {
            pictureView.image = UIImage(data: picture as Data)
        }
        
        countView.text = "\(metadata.albumCount) Albums, \(metadata.songCount) Songs"
    }
}

struct Metadata {
    var songCount: Int
    var albumCount: Int
    var picture: Data?
}

class ArtistsTableViewController: UITableViewController {
    static let songCountKey = "songs"
    static let albumCountKey = "albums"
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var artists = [NSDictionary]()
    var additionalData = [Metadata]()
    var library: Library?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        navigationItem.title = "All Artists"
        library = appDelegate.library
        
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell", for: indexPath) as! ArtistCell

        let result = artists[indexPath.item]
        let metadata = additionalData[indexPath.item]
        cell.setData(result, metadata)

        return cell
    }
    
    private func loadData() {
        
        guard let library = library else {
            artists.removeAll()
            self.tableView.reloadData()
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [SongTable.artistColumnName]
        request.returnsDistinctResults = true
        request.sortDescriptors = [NSSortDescriptor(key:SongTable.artistColumnName, ascending: true)]
        request.predicate = NSPredicate(format: "\(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", library.id!)
        
        additionalData.removeAll()
        
        do {
            artists = try ctx.fetch(request) as! [NSDictionary]
            try artists.forEach { data in
                if let artistName = data[SongTable.artistColumnName] as? String {
                    let songsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
                    songsRequest.predicate = NSPredicate(format: "\(SongTable.artistColumnName) = %@ AND \(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", artistName, library.id!)
                    let songCount = try ctx.count(for: songsRequest)
                    
                    let albumsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
                    albumsRequest.resultType = .dictionaryResultType
                    albumsRequest.propertiesToFetch = [SongTable.albumColumnName]
                    albumsRequest.returnsDistinctResults = true
                    albumsRequest.predicate = NSPredicate(format: "\(SongTable.artistColumnName) = %@ AND \(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", artistName, library.id!)
                    let albums = try ctx.fetch(albumsRequest)
                    let albumCount = albums.count
                    
                    //ctx.count does not honour the distinct result flag...
                    //let albumCount = try ctx.count(for: albumsRequest)
                    
                    let pictureRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
                    pictureRequest.resultType = .dictionaryResultType
                    pictureRequest.propertiesToFetch = [SongTable.pictureColumnName]
                    pictureRequest.returnsDistinctResults = true
                    pictureRequest.predicate = NSPredicate(format: "\(SongTable.artistColumnName) = %@ AND \(SongTable.libraryColumnName).\(LibraryTable.idColumnName) = %@", artistName, library.id!)
                    let pictures = try ctx.fetch(pictureRequest) as! [NSDictionary]
                    
                    let metadata = Metadata(songCount: songCount, albumCount: albumCount, picture: pictures[0][SongTable.pictureColumnName] as? Data)
                    
                    let i = artists.index(of: data)
                    if i != nil {
                        additionalData.insert(metadata, at: i!)
                    }
                }
            }
        }
        catch {
            DDLogError("Failed to fetch entities: \(error)")
        }
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let albumsVC = segue.destination as? AlbumsTableViewController {
            if let artistCell = sender as? ArtistCell {
                albumsVC.artist = artistCell.artist
            }
        }
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
