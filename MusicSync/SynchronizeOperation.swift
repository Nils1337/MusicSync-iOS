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
    let semaphore = DispatchSemaphore(value: 0)
    let timeoutInSeconds = 10;
    
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
        do {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            try getLibraries()
            try getSongs()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            server!.lastSync = .Success
            appDelegate.saveContext()
            let data = ["server_name": server!.name!]
            NotificationCenter.default.post(name: Notifications.synchronizedNotification, object: nil, userInfo: data)
        }
        catch {
            print("Error during synchronization")
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            server!.lastSync = .Failure
            appDelegate.saveContext()
            let data = ["server_name": server!.name!]
            NotificationCenter.default.post(name: Notifications.synchronizationFailedNotification, object: nil, userInfo: data)
        }
    }
    
    
    func getLibraries() throws {
        let prot = server!.prot == .Http ? "http" : "https"
        let url = URL(string: prot + "://" + server!.url! + ":" + String(server!.port) + libraryUrl)
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
            
            self.semaphore.signal()
        }
        
        task.resume()
        
        guard semaphore.wait(timeout: DispatchTime.now() + .seconds(timeoutInSeconds)) == .success else {
            task.cancel()
            throw RuntimeError.Message("Error while waiting for Library synchronization")
        }
    }
    
    func saveLibraries(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("Error during JSON Deserialization!")
            return
        }

        
        librarySync = Sync(changes: json as! [[String : Any]], inEntityNamed: "Library", predicate: nil, dataStack: appDelegate.dataStack, operations: .all)
        
        //need to keep reference to delegate here because for some reason its a weak reference in Sync class...
        let delegate = LibraryDelegate(self)
        librarySync?.delegate = delegate
        
        librarySync?.start()
        librarySync?.waitUntilFinished()
        
        print("Libraries successfully synced!")
    }
    

    func getSongs() throws {
        let prot = server!.prot == .Http ? "http" : "https"
        let s = prot + "://" + server!.url! + ":" + String(server!.port) + songUrl
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
            
            self.semaphore.signal()
        }
        task.resume()
        
        guard semaphore.wait(timeout: DispatchTime.now() + .seconds(timeoutInSeconds)) == .success else {
            task.cancel()
            throw RuntimeError.Message("Error while waiting for Song synchronization")
        }
    }
    
    func saveSongs(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("Error during JSON Deserialization!")
            return
        }
        
        songSync = Sync(changes: json as! [[String : Any]], inEntityNamed: "Song", predicate: nil, dataStack: appDelegate.dataStack, operations: .all)
        
        //need to keep reference to delegate here because for some reason its a weak reference in Sync class...
        let delegate = SongDelegate(self)
        songSync?.delegate = delegate
        
        songSync?.start()
        songSync?.waitUntilFinished()

        print("Songs successfully synced!")

    }
}

class LibraryDelegate: SyncDelegate {
    
    var syncOp: SynchronizeOperation
    
    init(_ syncOp: SynchronizeOperation) {
        self.syncOp = syncOp
    }
    
    func insert(_ sync: Sync, willInsert json: [String : Any], in entityNamed: String, parent: NSManagedObject?) -> [String : Any] {
        
        //copy dictionary because passed one is immutable
        var update = json

        //add server id to library entity
        update.updateValue(syncOp.server!.name!, forKey: LibraryTable.serverColumnName + "_id")
        
        return update
    }
    
    func update(json: [String: Any], updateObject: NSManagedObject) -> [String: Any] {
        
        guard let library = updateObject as? Library else {
            return json
        }
        
        var update = json;
        
        if let server = library.server {
            update.updateValue(server.name!, forKey: LibraryTable.serverColumnName + "_id")
        }
        
        return update;
    }
}

class SongDelegate: SyncDelegate {
    var syncOp: SynchronizeOperation
    
    init(_ syncOp: SynchronizeOperation) {
        self.syncOp = syncOp
    }
    
    func insert(_ sync: Sync, willInsert json: [String : Any], in entityNamed: String, parent: NSManagedObject?) -> [String : Any] {
        
        //copy dictionary because passed one is immutable
        var update = json
        
        //add server id to library entity
        guard let serverName = syncOp.server?.name else {
            return json;
        }
        update.updateValue(serverName, forKey: SongTable.serverColumnName + "_id")
        
        update.updateValue(Song.DownloadStatus.Remote.rawValue, forKey: SongTable.downloadStatusColumnName)
        if let library = update[SongTable.libraryColumnName] {
            update.updateValue(library, forKey: SongTable.libraryColumnName + "_id")
        }
        update.removeValue(forKey: SongTable.libraryColumnName)
        
        //Decode picture
        if let pictureEncoded = update[SongTable.pictureColumnName] as? String {
            let picture = Data(base64Encoded: pictureEncoded)
            if let pic = picture {
                update.updateValue(pic, forKey: SongTable.pictureColumnName)
            } else {
                update.removeValue(forKey: SongTable.pictureColumnName)
            }
        }
        
        return update
    }
    
    func update(json: [String: Any], updateObject: NSManagedObject) -> [String: Any] {
        guard let song = updateObject as? Song else {
            return json
        }
        
        var update = json;
        
        //update server
        guard let serverName = song.server?.name else {
            return json;
        }
        
        update.updateValue(serverName, forKey: SongTable.serverColumnName + "_id")
        
        //update library
        if let library = update[SongTable.libraryColumnName] {
            update.updateValue(library, forKey: SongTable.libraryColumnName + "_id")
        }
        update.removeValue(forKey: SongTable.libraryColumnName)
        
        //Decode picture
        if let pictureEncoded = update[SongTable.pictureColumnName] as? String {
            let picture = Data(base64Encoded: pictureEncoded)
            if let pic = picture {
                update.updateValue(pic, forKey: SongTable.pictureColumnName)
            } else {
                update.removeValue(forKey: SongTable.pictureColumnName)
            }
        }
        
        //update downloadStatus
        update.updateValue(song.downloadStatus.rawValue, forKey: "download_status")

        //update filename
        if let filename = update[SongTable.filenameColumnName] {
            update.updateValue(filename, forKey: SongTable.filenameColumnName)
        }
        
        return update;
    }
}
