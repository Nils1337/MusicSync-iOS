//
//  SynchronizeOperation.swift
//  MusicSync
//
//  Created by nils on 30.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import Foundation
import UIKit
import Sync

class SynchronizeOperation: Operation {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let libraryQueue = OperationQueue()
    let songQueue = OperationQueue()
    
    let songUrl = "/songs"
    let libraryUrl = "/libraries"
    let server: Server?
    
    var songSync: Sync?
    var librarySync: Sync?
    
    init(_ server: Server?) {
        self.server = server
    }
    
    override func main() {
        guard server != nil else {
            print("Current Server is null!")
            return
        }
        
        getSongs()
        getLibraries()
    }
    
    func getSongs() {
        let s = "http://" + server!.url! + ":" + String(server!.port) + songUrl
        let url = URL(string: s)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil else {
                //TODO
                print(error!.localizedDescription)
                return
            }
            
            guard data != nil else {
                //TODO
                print("no data received from server!")
                return
            }
            
            if let r = response as? HTTPURLResponse {
                if (r.statusCode == 200) {
                    self.saveSongs(data!)
                }
            }
        }
        
        task.resume()
    }
    
    func saveSongs(_ data: Data) {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        songSync = Sync(changes: json as! [[String : Any]], inEntityNamed: "Song", predicate: nil, dataStack: appDelegate.dataStack)
        songSync?.delegate = SongDelegate(self)
        songSync?.start()
        
        //We're already in a background thread so we can wait here until synchronization is finished
        songSync?.waitUntilFinished()

        print("Songs successfully synced!")
        NotificationCenter.default.post(name: NSNotification.Name("SongsSynchronized"), object: nil)


    }
    
    func notification(notification: Notification) {
        print("muh!")
    }
    
    func getLibraries() {
        let url = URL(string: "http://" + server!.url! + ":" + String(server!.port) + libraryUrl)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil else {
                //TODO
                print(error!.localizedDescription)
                return
            }
            
            guard data != nil else {
                //TODO
                print("no data received from server!")
                return
            }
            
            if let r = response as? HTTPURLResponse {
                if (r.statusCode == 200) {
                    self.saveLibraries(data!)
                }
            }
        }
        
        task.resume()
    }
    
    func saveLibraries(_ data: Data) {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        librarySync = Sync(changes: json as! [[String : Any]], inEntityNamed: "Library", predicate: nil, dataStack: appDelegate.dataStack)
        librarySync?.delegate = LibraryDelegate(self)
        librarySync?.start()
        
        //We're already in a background thread so we can wait here until synchronization is finished
        librarySync?.waitUntilFinished()

        print("Libraries successfully synced!")
        NotificationCenter.default.post(name: NSNotification.Name("LibrariesSynchronized"), object: nil)
    }
}

class LibraryDelegate: SyncDelegate {
    
    var syncOp: SynchronizeOperation
    
    init(_ syncOp: SynchronizeOperation) {
        self.syncOp = syncOp
    }
    
    func sync(_ sync: Sync, willInsert json: [String : Any], in entityNamed: String, parent: NSManagedObject?) -> [String : Any] {
        
        //add server id to library entity
        var update = json
        update.updateValue(syncOp.server!.id, forKey: LibraryTable.serverColumnName)
        return update
    }
}

class SongDelegate: SyncDelegate {
    var syncOp: SynchronizeOperation
    
    init(_ syncOp: SynchronizeOperation) {
        self.syncOp = syncOp
    }
    
    func sync(_ sync: Sync, willInsert json: [String : Any], in entityNamed: String, parent: NSManagedObject?) -> [String : Any] {
        return json
    }
}
