//
//  LibraryTableViewController.swift
//  MusicSync
//
//  Created by nils on 28.06.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import CoreData
import MMDrawerController

class LibraryCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    var library: Library?
    
    func setData(_ library: Library) {
        self.library = library
        nameLabel.text = library.name
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let background = UIView()
        background.backgroundColor = UIColor.libraryHighlightColor()
        selectedBackgroundView = background
    }

    /*override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if (highlighted) {
            backgroundColor = UIColor.libraryHighlightColor()
        } else {
            backgroundColor = UIColor.clear
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if (selected) {
            backgroundColor = UIColor.libraryHighlightColor()
        } else {
            backgroundColor = UIColor.clear
        }
    }*/
}

class DrawerServerCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    var server: Server?
    
    func setData(_ server: Server) {
        self.server = server
        nameLabel.text = server.name! + " @ " + server.url!
    }
}

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var data = [Any]()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        super.viewDidLoad()
        navigationItem.title = "Libraries"
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notifications.synchronizedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notifications.synchronizationFailedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notifications.serverAddedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notifications.libraryChangedNotification, object: nil)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //select current library
        data.enumerated().forEach {
            if let library = $1 as? Library {
                if (appDelegate.library?.id! == library.id!) {
                    let indexPath = IndexPath(row: $0, section: 0)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
                }
            }
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        /*if let frc = fetchedController {
            return frc.sections!.count
        }
        return 0*/
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /*guard let sections = self.fetchedController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects*/
        return data.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if data[indexPath.row] is Library {
            return 45
        } else {
            return 25
        }
    }
/*
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LibraryCell else {
            return;
        }
        cell.backgroundColor = UIColor.libraryHighlightColor()
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LibraryCell else {
            return;
        }
        cell.backgroundColor = UIColor.clear
    }*/

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let object = data[indexPath.row]
        
        if let server = object as? Server {
            let cell = tableView.dequeueReusableCell(withIdentifier: "drawerServerCell", for: indexPath) as! DrawerServerCell
            cell.setData(server)
            return cell
        } else if let library = object as? Library {
            let cell = tableView.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath) as! LibraryCell
            cell.setData(library)
            return cell
        } else if object is String {
            return tableView.dequeueReusableCell(withIdentifier: "errorCell", for: indexPath)
        } else {
            fatalError("Attempt to configure cell without managed object")
        }
    }
 
    private func loadData() {

        let ctx = appDelegate.dataStack.mainContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Server")
        request.resultType = .managedObjectResultType
        let s = NSSortDescriptor(key: ServerTable.nameColumnName, ascending: true)
        request.sortDescriptors = [s]
        do {
            let servers = try ctx.fetch(request) as! [Server]
            data = servers
            for server in servers {
                let libRequest  = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
                libRequest.resultType = .managedObjectResultType
                libRequest.sortDescriptors = [NSSortDescriptor(key: LibraryTable.nameColumnName, ascending: true)]
                libRequest.predicate = NSPredicate(format: "\(LibraryTable.serverColumnName).\(ServerTable.nameColumnName) = %@", server.name!)
                let libraries = try ctx.fetch(libRequest) as! [Library]
                libraries.reversed().forEach {
                    data.insert($0, at: 1 + data.index(where: {
                        s in
                        return s as? Server == server
                    })!)
                }
                
                //add error indicator
                if server.lastSync == .Failure {
                    data.insert("error", at: 1 + data.index(where: {
                        s in
                        return s as? Server == server
                    })!)
                }
            }
        }
        catch {
            fatalError("Failed to fetch entities: \(error)")
        }
        self.tableView.reloadData()
    }
    
    /*func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedController?.sections?[section]
        let library = sectionInfo?.objects?[0] as? Library
        guard let server = library?.server else {
            return "error"
        }
        return "\(server.name!) @ \(server.url!)"
    }*/
    
    func reload(_ notification: NSNotification) {
        OperationQueue.main.addOperation {
            self.loadData()
        }
    }
    
    /*func showSyncError(_ notification: NSNotification) {
        guard notification.userInfo != nil else {
            return
        }
        let serverName = notification.userInfo!["server_name"] as? String
        guard serverName != nil else {
            return
        }
        
        var index = -1
        data.enumerated().forEach {
            if let server = $1 as? Server {
                if (serverName == server.name!) {
                    index = $0
                }
            }
        }
        if index > -1 {
            data.insert("error", at: index + 1)
            let indexPath = IndexPath(row: index + 1, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    func syncSuccess(_ notification: NSNotification) {
        guard notification.userInfo != nil else {
            return
        }
        let serverName = notification.userInfo!["server_name"] as? String
        guard serverName != nil else {
            return
        }
        
        var index = -1
        data.enumerated().forEach {
            if let server = $1 as? Server {
                if (serverName == server.name!) {
                    index = $0
                }
            }
        }
        if index > -1 {
            if index + 1 < data.count && data[index+1] is String {
                data.remove(at: index + 1)
                let indexPath = IndexPath(row: index + 1, section: 0)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        reload(notification)
    }*/
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LibraryCell else {
            return
        }
        let library = cell.library
        appDelegate.server = library?.server
        appDelegate.library = library
        appDelegate.drawerContainer?.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
