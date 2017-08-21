//
//  SongsOfAlbumViewController.swift
//  MusicSync
//
//  Created by nils on 20.08.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit

class SongsOfAlbumViewController: UIViewController {
    
    var artist: String?
    var album: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let songsVC = segue.destination as? SongsTableViewController {
            songsVC.album = album
            songsVC.artist = artist
        }
    }

}
