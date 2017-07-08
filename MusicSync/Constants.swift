//
//  Constants.swift
//  MusicSync
//
//  Created by nils on 25.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import Foundation

struct SongTable {
    static let artistColumnName = "artist"
    static let albumColumnName = "album"
    static let titleColumnName = "title"
    static let libraryColumnName = "library"
    static let serverColumnName = "server"
    static let localIdColumnName = "localId"
    static let remoteIdColumnName = "remoteId"
}

struct ServerTable {
    static let nameColumnName = "name"
}

struct LibraryTable {
    static let nameColumnName = "name"
    static let serverColumnName = "server"
    static let localIdColumnName = "localId"
    static let remoteIdColumnName = "remoteId"
}

struct Notifications {
    static let synchronizedNotification = NSNotification.Name("synchronized")
    static let serverDeletedNoticiation = NSNotification.Name("serverDeleted")
    static let allDataDeletedNotification = NSNotification.Name("allDataDeleted")
    static let libraryChangedNotification = NSNotification.Name("libraryChanged")
    static let serverChangedNotification = NSNotification.Name("serverChanged")
    static let serverAddedNotification = NSNotification.Name("serverAdded")
}
