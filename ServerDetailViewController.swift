//
//  ServerDetailViewController.swift
//  MusicSync
//
//  Created by nils on 25.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData

class ServerDetailViewController: UIViewController {
    
    var server: Server?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initiate view with passed data
        if let s = server {
            nameField.text = s.name
            portField.text = String(s.port)
            addressField.text = s.url
        }
        //or create new server entity
 
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDoneButtonPressed))
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onDoneButtonPressed() {
        
        if server == nil {
            let ctx = appDelegate.dataStack.mainContext
            server = NSEntityDescription.insertNewObject(forEntityName: "Server", into: ctx) as? Server
        }
        
        server!.name = nameField.text
        server!.url = addressField.text
        server!.port = Int16(portField.text!)!
        
        appDelegate.saveContext()
        appDelegate.synchronize(with: server!)
        performSegue(withIdentifier: "unwindToServers", sender: self)
    }
    
    /*@IBAction func unwindToServers(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        server!.name = nameField.text
        server!.url = addressField.text
        server!.port = Int16(portField.text!)!
        
        appDelegate.saveContext()
    }*/

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}