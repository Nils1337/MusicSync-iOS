//
//  AllSongsViewController.swift
//  MusicSync
//
//  Created by nils on 20.08.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit

class AllSongsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func drawerButtonClicked(_ sender: UIBarButtonItem) {
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

}
