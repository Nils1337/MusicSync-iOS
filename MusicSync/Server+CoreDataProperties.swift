//
//  Server+CoreDataProperties.swift
//  MusicSync
//
//  Created by nils on 18.08.17.
//  Copyright © 2017 nils. All rights reserved.
//

import Foundation
import CoreData


extension Server {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Server> {
        return NSFetchRequest<Server>(entityName: "Server")
    }
    
    @objc public enum Prot: Int16 {
        case Http, Https
    }
    
    @NSManaged public var name: String?
    @NSManaged public var path: String?
    @NSManaged public var port: Int16
    @NSManaged public var url: String?
    @NSManaged public var prot: Prot
    @NSManaged public var libraries: NSSet?
    @NSManaged public var songs: NSSet?

}

// MARK: Generated accessors for libraries
extension Server {

    @objc(addLibrariesObject:)
    @NSManaged public func addToLibraries(_ value: Library)

    @objc(removeLibrariesObject:)
    @NSManaged public func removeFromLibraries(_ value: Library)

    @objc(addLibraries:)
    @NSManaged public func addToLibraries(_ values: NSSet)

    @objc(removeLibraries:)
    @NSManaged public func removeFromLibraries(_ values: NSSet)

}

// MARK: Generated accessors for songs
extension Server {

    @objc(addSongsObject:)
    @NSManaged public func addToSongs(_ value: Song)

    @objc(removeSongsObject:)
    @NSManaged public func removeFromSongs(_ value: Song)

    @objc(addSongs:)
    @NSManaged public func addToSongs(_ values: NSSet)

    @objc(removeSongs:)
    @NSManaged public func removeFromSongs(_ values: NSSet)

}
