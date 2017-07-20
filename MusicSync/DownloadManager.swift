//
//  Downloader.swift
//  MusicSync
//
//  Created by nils on 18.07.17.
//  Copyright © 2017 nils. All rights reserved.
//

import Foundation
import ReachabilitySwift
import UIKit

protocol DownloadDelegate {
    func downloadFinished(_ song: Download)
    func update()
}

struct Download {
    var song: Song
    var task: URLSessionDownloadTask
}

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    
    static let shared = DownloadManager()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Bundle.main.bundleIdentifier!)
        return URLSession(configuration: config, delegate: self as URLSessionDelegate, delegateQueue: nil)
    }()
    
    static let downloadUrl = "/songs/download"
    var downloads = [Download]()
    var delegate: DownloadDelegate?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged), name: ReachabilityChangedNotification, object: appDelegate.reachability)
        do {
            try appDelegate.reachability.startNotifier()
        }
        catch {
            print("could not start reachability notifier!")
        }
    }
    
    func addDownload(server: Server, song: Song) {
        let url = URL(string: "http://" + server.url! + ":" + String(server.port) + DownloadManager.downloadUrl + "/" + song.id!)
        let request = URLRequest(url: url!)
        let download = session.downloadTask(with: request)
        downloads.append(Download(song: song, task: download))
        
        song.downloadStatus = .Downloading
        appDelegate.saveContext()
        
        if downloads.count == 1 {
            print("starting download of song \(song.title!)")
            if (appDelegate.isWifiConnected()) {
                download.resume()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard downloads.count > 0 else {
            print("download finished method invoked but no download in queue!")
            return
        }
        let download = downloads[0]

        print("download of song \(download.song.title!) finished")
        downloads.remove(at: 0)
        if downloads.count > 0 {
            let download = downloads[0]
            print("starting download of song \(download.song.title!)")
            download.task.resume()
        }
        
        let fileManager = FileManager.default
        let libraryPath = NSHomeDirectory() + "/" + download.song.library!.id!
        let filePath = libraryPath + "/" + download.song.id!
        do {
            if !fileManager.fileExists(atPath: libraryPath) {
                try fileManager.createDirectory(atPath: libraryPath, withIntermediateDirectories: false, attributes: nil)
            }
            try fileManager.copyItem(at: location, to: URL(fileURLWithPath: filePath))
            
            download.song.downloadStatus = .Local
            download.song.filename = filePath
            
            
            delegate?.downloadFinished(download)
        }
        
        catch {
            print("error trying to create copy file!")
        }
    }
    
    func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability
        
        if reachability.isReachableViaWiFi {
            if downloads.count > 0 {
                downloads[0].task.resume()
            }
        }
    }
}
