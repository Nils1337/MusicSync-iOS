//
//  SynchronizeOperation.swift
//  MusicSync
//
//  Created by nils on 30.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import Foundation

class SynchronizeOperation: Operation {
    
    let songUrl = "/songs"
    let libraryUrl = "/libraries"
    let server: Server?
    
    init(_ server: Server?) {
        self.server = server
    }
    
    override func main() {
        guard server != nil else {
            print("Current Server is null!")
            return
        }
        print("operation invoked!")
    }
    
    func getSongs() {
        let url = URL(string: "http://" + server!.url! + ":" + String(server!.port) + songUrl)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        session.dataTask(with: request) {
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
    }
    
    func saveSongs(_ data: Data) {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        let song = Song(JSONString: json.toString())
    }
    
    func getLibraries() {
        let url = URL(string: "http://" + server!.url! + ":" + String(server!.port) + libraryUrl)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        session.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil else {
                //TODO
                print(error!.localizedDescription)
                return
            }
            
            if let r = response as? HTTPURLResponse {
                if (r.statusCode == 200) {
                    self.saveLibraries(data)
                }
            }
        }
    }
    
    func saveLibraries(_ data: Data?) {
        
    }
}
