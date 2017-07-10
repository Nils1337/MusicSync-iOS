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
            try getLibraries()
            try getSongs()
        }
        catch {
            print("Error during synchronization")
        }
    }
    
    
    func getLibraries() throws {
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
            
            self.semaphore.signal()
        }
        
        task.resume()
        
        guard semaphore.wait(timeout: DispatchTime.now() + .seconds(timeoutInSeconds)) == .success else {
            throw NSError()
        }
    }
    
    func saveLibraries(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("Error during JSON Deserialization!")
            return
        }
        
        
        //just delete all old data (maybe a bit slow but easier)
        
        /*
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
        let predicate = NSPredicate(format: "\(LibraryTable.serverColumnName).\(ServerTable.nameColumnName) = %@", server!.name!)
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try appDelegate.dataStack.mainContext.execute(deleteRequest)
        } catch {
            print("Error trying to delete libraries!")
        }*/
        
        librarySync = Sync(changes: json as! [[String : Any]], inEntityNamed: "Library", predicate: nil, dataStack: appDelegate.dataStack, operations: .all)
        
        //need to keep reference to delegate here because for some reason its a weak reference in Sync class...
        let delegate = LibraryDelegate(self)
        librarySync?.delegate = delegate
        
        librarySync?.start()
        librarySync?.waitUntilFinished()
        
        print("Libraries successfully synced!")
    }
    

    func getSongs() throws {
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
            
            self.semaphore.signal()
        }
        task.resume()
        
        guard semaphore.wait(timeout: DispatchTime.now() + .seconds(timeoutInSeconds)) == .success else {
            throw NSError()
        }
    }
    
    func saveSongs(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("Error during JSON Deserialization!")
            return
        }
        
        //just delete all old data (maybe a bit slow but easier)
        
        /*
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        let predicate = NSPredicate(format: "\(SongTable.serverColumnName).\(ServerTable.nameColumnName) = %@", server!.name!)
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try appDelegate.dataStack.mainContext.execute(deleteRequest)
        } catch {
            print("Error trying to delete songs!")
        }*/
        
        
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
        
        //set local id (concatenate remoteId with server id)
        /*
        let remoteId = update["id"] as! Int64
        let localId = String(remoteId) + syncOp.server!.name!
        update.updateValue(localId, forKey: "id")
        update.updateValue(remoteId, forKey: LibraryTable.remoteIdColumnName)*/
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
        update.updateValue(syncOp.server!.name!, forKey: SongTable.serverColumnName + "_id")
        
        /*
        //set local id (concatenate remoteId with server id)
        let remoteId = update["id"] as! Int64
        let localId = String(remoteId) + syncOp.server!.name!
        update.updateValue(localId, forKey: "id")
        update.updateValue(remoteId, forKey: SongTable.remoteIdColumnName)
 
        
        //get correct library with localId
        let libraryRemoteId = update[SongTable.libraryColumnName] as! Int64
        let predicate = NSPredicate(format: "\(LibraryTable.remoteIdColumnName) = %lld AND \(LibraryTable.serverColumnName).\(ServerTable.nameColumnName) = %@", libraryRemoteId, syncOp.server!.name!)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
        fetchRequest.predicate = predicate
        let result = try? syncOp.appDelegate.dataStack.mainContext.fetch(fetchRequest)
        guard let library = result?.first as? Library else {
            print("Couldnt retrieve library when synchronizing songs!")
            return json
        }
        
        //fix library key for correct relationship
        update.removeValue(forKey: SongTable.libraryColumnName)
        update.updateValue(library.localId!, forKey: SongTable.libraryColumnName + "_id")
        */
        
        update.updateValue(0, forKey: SongTable.downloadedColumnName)
        if let library = update[SongTable.libraryColumnName] {
            update.updateValue(library, forKey: SongTable.libraryColumnName + "_id")
        }
        update.removeValue(forKey: SongTable.libraryColumnName)
        
        //update.updateValue(nil, forKey: SongTable.filenameColumnName)
        
        return update
    }
    
    func update(json: [String: Any], updateObject: NSManagedObject) -> [String: Any] {
        guard let song = updateObject as? Song else {
            return json
        }
        
        var update = json;
        
        if let server = song.server {
            update.updateValue(server.name!, forKey: SongTable.serverColumnName + "_id")
        }
        
        update.updateValue(0, forKey: SongTable.downloadedColumnName)
        if let library = update[SongTable.libraryColumnName] {
            update.updateValue(library, forKey: SongTable.libraryColumnName + "_id")
        }
        update.removeValue(forKey: SongTable.libraryColumnName)
        
        update.updateValue(song.downloaded, forKey: SongTable.downloadedColumnName)

        if let filename = update[SongTable.filenameColumnName] {
            update.updateValue(filename, forKey: SongTable.filenameColumnName)
        }
        
        return update;
    }
}
