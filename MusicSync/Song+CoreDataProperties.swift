//
//  Song+CoreDataProperties.swift
//  
//
//  Created by nils on 18.07.17.
//
//

import Foundation
import CoreData


extension Song {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }
    
    @objc public enum DownloadStatus: Int16 {
        case Remote, Downloading, Local
    }

    @NSManaged public var album: String?
    @NSManaged public var artist: String?
    @NSManaged public var downloadStatus: DownloadStatus
    @NSManaged public var filename: String?
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var library: Library?
    @NSManaged public var server: Server?

}
