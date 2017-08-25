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
import CocoaLumberjack

protocol DownloadDelegate {
    func downloadFinished(_ song: Download)
    func update()
    func error(_ error: Error)
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
            DDLogWarn("could not start reachability notifier!")
        }
    }
    
    func addDownload(server: Server, song: Song) {
        let prot = server.prot == .Http ? "http" : "https"
        let url = URL(string: "\(prot)://\(server.url!):\(String(server.port))\(DownloadManager.downloadUrl)/\(song.id!)")
        let request = URLRequest(url: url!)
        let download = session.downloadTask(with: request)
        downloads.append(Download(song: song, task: download))
        
        song.downloadStatus = .Downloading
        appDelegate.saveContext()
        
        if downloads.count == 1 {
            DDLogInfo("starting download of song \(song.title!)")
            if (appDelegate.isWifiConnected()) {
                download.resume()
            }
        }
    }
    
    func cancelDownloads(of server: Server) {
        for download in downloads {
            if (download.song.server! == server) {
                download.task.cancel()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            delegate?.error(error!)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard downloads.count > 0 else {
            delegate?.error(RuntimeError.Message("A Download was finished but no task entity is present!"))
            return
        }
        
        let download = downloads[0]

        DDLogInfo("download of song \(download.song.title!) finished")
        downloads.remove(at: 0)
        if downloads.count > 0 {
            let download = downloads[0]
            DDLogInfo("starting download of song \(download.song.title!)")
            download.task.resume()
        }
        
        guard let response = downloadTask.response else {
            delegate?.error(RuntimeError.Message("No response!"))
            return
        }
        
        guard let mime = response.mimeType else {
            delegate?.error(RuntimeError.Message("No mime type specified in response!"))
            return
        }
        
        guard mime.hasPrefix("audio") else {
            delegate?.error(RuntimeError.Message("Wrong mime type!"))
            return
        }
        
        guard mime.hasSuffix("mpeg") else {
            delegate?.error(RuntimeError.Message("Wrong mime type!"))
            return
        }
        
        let pathExtension = "mp3"
        
        /*let i = mime.lastIndex(of: "/")
        
        guard let index = i else {
            delegate?.error(RuntimeError.Message("Wrong mime type!"))
            return
        }
        
        let pathExtension = mime.substring(from: mime.index(mime.startIndex, offsetBy: index + 1))
        */
        let fileManager = FileManager.default
        do {
            
            let dirUrl = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let libUrl = dirUrl.appendingPathComponent(download.song.library!.id!)
            let fileUrl = libUrl.appendingPathComponent(download.song.id!).appendingPathExtension(pathExtension)

            if !fileManager.fileExists(atPath: libUrl.path) {
                try fileManager.createDirectory(at: libUrl, withIntermediateDirectories: false, attributes: nil)
            }
            if fileManager.fileExists(atPath: fileUrl.path) {
                try fileManager.removeItem(at: fileUrl)
            }
            try fileManager.moveItem(at: location, to: fileUrl)
            
            
            download.song.downloadStatus = .Local
            download.song.filename = libUrl.lastPathComponent + "/" + fileUrl.lastPathComponent
            DDLogVerbose("Saved song to file " + download.song.filename!)

            appDelegate.saveContext()
            
            delegate?.downloadFinished(download)
        }
        catch {
            download.song.downloadStatus = .Remote
            appDelegate.saveContext()
            delegate?.error(error)
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
