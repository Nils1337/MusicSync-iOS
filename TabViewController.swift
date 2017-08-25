//
//  TabViewController.swift
//  MusicSync
//
//  Created by nils on 30.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData
import MMDrawerController

class TabViewController: UITabBarController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func toggleDrawer() {
        appDelegate.drawerContainer?.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func unwindToServers(segue: UIStoryboardSegue) {
        
    }
}
