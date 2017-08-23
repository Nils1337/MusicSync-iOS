//
//  PlayingViewController.swift
//  MusicSync
//
//  Created by nils on 23.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import AVFoundation

class PlayingViewController: UIViewController {
    
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var artistView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    var player = AVPlayer()
    var items: [AVPlayerItem] = []
    var songs: [Song] = []
    var index = 0
    var observerToken: Any?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(serverDeleted(_:)), name: Notifications.serverDeletedNoticiation, object: nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (items.count > 0) {
            updateView(items[index])
        
            let interval = CMTime(seconds: 0.25,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            observerToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) {
                [weak self] (time: CMTime) in
            
                print(time)
            
                guard self != nil else {
                    return;
                }
            
                self!.progressView.setProgress(Float(time.seconds) / Float(self!.items[self!.index].duration.seconds), animated: true)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if observerToken != nil {
            player.removeTimeObserver(observerToken!)
            observerToken = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func drawerButtonClicked(_ sender: Any) {
            (self.tabBarController as! TabViewController).toggleDrawer()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func serverDeleted(_ notification: Notification) {
        if let serverName = notification.userInfo?["server_name"] as? String, songs.count > 0, songs[0].server!.name! == serverName {
            player.pause()
            imageView.image = nil
            progressView.setProgress(0, animated: true)
        }
    }
    
    
    @IBAction func playOrPause(_ sender: Any) {
        if (isPlaying()) {
            player.pause()
            updatePlayButtonImage(false)
        } else {
            player.play()
            updatePlayButtonImage(true)
        }
    }
    
    @IBAction func next() {
        let newIndex = index >= items.count - 1 ? 0 : index + 1
        if (items[newIndex] == player.currentItem) {
            player.seek(to: kCMTimeZero)
        } else {
            items[index].removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            items[newIndex].addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
            index = newIndex
            player.replaceCurrentItem(with: items[index])
            player.seek(to: kCMTimeZero)
        }
        updateView(items[index])
    }
    
    @IBAction func prev() {
        let newIndex = index < 1 ? items.count - 1 : index - 1
        if (items[newIndex] == player.currentItem) {
            player.seek(to: kCMTimeZero)
        } else {
            items[index].removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            items[newIndex].addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
            index = newIndex
            player.replaceCurrentItem(with: items[index])
            player.seek(to: kCMTimeZero)
        }
        updateView(items[index])
    }
    
    func startPlaying(_ songs: [Song]) {
        self.songs = songs
        
        if (items.count > 0) {
            items[index].removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        }
        
        self.items = []
        
        var dirUrl: URL?
        do {
            dirUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            print("Document directory could not be accessed!")
            return
        }
        
        songs.forEach {
            let item = AVPlayerItem(url: dirUrl!.appendingPathComponent($0.filename!))
            print($0.filename!)
            items.append(item)
        }
        index = 0
        //player = AVPlayer()
        
        items[index].addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        print(items[index].status.rawValue)
        player.replaceCurrentItem(with: items[index])
        //player.play()
    }
    
    func updateView(_ item: AVPlayerItem) {
        
        let i = items.index(of: item)
        
        guard let index = i else {
            return;
        }
        let song = songs[index]
        
        titleView.text = song.title
        artistView.text = song.artist
        if let picture = song.picture {
            imageView.image = UIImage(data: picture)
        } else {
            imageView.image = nil
        }
        
        updatePlayButtonImage(isPlaying())
    }
    
    func updatePlayButtonImage(_ playing: Bool) {
        if (playing) {
            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        } else {
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
    }
    
    func isPlaying() -> Bool {
        if #available(iOS 10.0, *) {
            if (player.timeControlStatus == .playing) {
                return true
            } else {
                return false
            }
        } else {
            if (player.rate > 0 && player.error == nil) {
                return true
            } else {
                return false
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == #keyPath(AVPlayerItem.status)) {
            let status: AVPlayerItemStatus
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            let item = object as! AVPlayerItem

            switch(status) {
            case .readyToPlay:
                player.play()
                updateView(item)
                break
            case .failed:
                let alert = UIAlertController(title: "Playback Error", message: "\(item.error!)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                break
            case .unknown:
                //do nothing
                break
            }
            
        }
    }
    
    @IBAction func unwindToServers(segue: UIStoryboardSegue) {
        
    }
    

}
