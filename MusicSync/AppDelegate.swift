//
//  AppDelegate.swift
//  MusicSync
//
//  Created by nils on 11.05.17.
//  Copyright © 2017 nils. All rights reserved.
//

import UIKit
import MMDrawerController
import CoreData
import Sync
import ReachabilitySwift
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let synchronizeQueue = OperationQueue()
    let dataFetchQueue = OperationQueue()
    let reachability = Reachability()!

    let dataStack = DataStack(modelName: "DataModel")
    
    var window: UIWindow?
    var drawerContainer: MMDrawerController?
    var centerViewController: UIViewController?
    
    var server: Server? {
        /*
        willSet(newValue) {
            if (newValue == nil) {
                //cancel all current synchronizations with server if it is deleted
                for operation in synchronizeQueue.operations {
                    if let op = operation as? SynchronizeOperation, op.server == server {
                        op.cancel()
                    }
                }
                
                //cancel all current downloads from server if it is deleted
                if server != nil {
                    DownloadManager.shared.cancelDownloads(of: server!)
                }
            }
        }*/
        didSet(oldValue) {
            NotificationCenter.default.post(name: Notifications.serverChangedNotification, object: nil)
        }
    }
    var library: Library? {
        didSet(oldValue) {
            NotificationCenter.default.post(name: Notifications.libraryChangedNotification, object: nil)
        }
    }

    let serverKey = "server"
    let libraryKey = "library"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        centerViewController = mainStoryboard.instantiateViewController(withIdentifier: "MainViewController") as UIViewController
        
        let drawerViewController = mainStoryboard.instantiateViewController(withIdentifier: "DrawerController") as UIViewController
        
        let nav = UINavigationController()
        nav.setViewControllers([drawerViewController], animated: false)
        nav.title = "Libraries"
        
        drawerContainer = MMDrawerController(center: centerViewController, leftDrawerViewController: nav)
        drawerContainer?.openDrawerGestureModeMask = MMOpenDrawerGestureMode.bezelPanningCenterView
        drawerContainer?.closeDrawerGestureModeMask = [MMCloseDrawerGestureMode.panningCenterView, MMCloseDrawerGestureMode.panningDrawerView, MMCloseDrawerGestureMode.tapCenterView]
        drawerContainer?.showsShadow = false
        drawerContainer?.setDrawerVisualStateBlock(animateDrawer)
        drawerContainer?.setMaximumLeftDrawerWidth(200, animated: true, completion: nil)

        window!.rootViewController = drawerContainer
        window!.makeKeyAndVisible()
        
        
        UINavigationBar.appearance().barTintColor = UIColor.navBarColor()
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        /*let defaults = UserDefaults.standard
         let serverName = defaults.object(forKey: serverKey)
         let libraryId = defaults.object(forKey: libraryKey)*/
        //deleteAllData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(trySelectLibrary), name: Notifications.synchronizedNotification, object: nil)
        
        //configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        }
        catch {
            print("Setting category of AVAudioSession failed!")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let defaults = UserDefaults.standard
        defaults.set(server?.name!, forKey: serverKey)
        defaults.set(library?.id!, forKey: libraryKey)
   }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        synchronizeWithCurrentServer()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        //gets called when application is started by background session that is finished downloading
        completionHandler()
    }
    
    @objc func onDrawerButtonPressed() {
        drawerContainer?.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }

    func animateDrawer(drawerController: MMDrawerController?, drawerSide: MMDrawerSide, percentVisible: CGFloat) {
        centerViewController?.view.alpha = 1 - (percentVisible * 0.5)
        
        //do provided animation
        let block = MMDrawerVisualState.slideVisualStateBlock()
        block?(drawerController, drawerSide, percentVisible)
    }
    
    func synchronizeWithCurrentServer() {
        if library == nil {
            let operation = BlockOperation {
                if self.server == nil {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Server")
                    let result = try? self.dataStack.mainContext.fetch(request)
                    self.server = result?.first as? Server
                }
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
                let result = try? self.dataStack.mainContext.fetch(request)
                self.library = result?.first as? Library
            }
            
            operation.completionBlock = {
                OperationQueue.main.addOperation {
                    if let server = self.server {
                        self.synchronize(with: server)
                    }
                }
            }
            
            dataFetchQueue.addOperation(operation)
        }
        else {
            //if library is not nil, server should not be nil as well
            guard let server = server else {
                print("Could not synchronize with current server because library is set but server is nil!")
                return
            }
            synchronize(with: server)
        }
    }
    
    func trySelectLibrary(_ notification: NSNotification) {
        dataFetchQueue.addOperation {
            if self.server != nil && self.library == nil {
                //try to set a library
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
                let predicate = NSPredicate(format: "\(LibraryTable.serverColumnName).\(ServerTable.nameColumnName)  = %@", self.server!.name!)
                request.predicate = predicate
                let result = try? self.dataStack.mainContext.fetch(request)
                self.library = result?.first as? Library
            }
        }
    }
    
    
    func synchronize(with server: Server) {
        let op = SynchronizeOperation(server)
        
        if self.server == nil {
            self.server = server
        }
        
        print("Synchronization started with server: " + server.name!)
        
        synchronizeQueue.addOperation(op)
        

    }
    
    func deleteAllData() {
        let request: NSFetchRequest<Server> = Server.fetchRequest()
        do {
            let servers = try dataStack.mainContext.fetch(request)
            for server in servers {
                deleteFiles(of: server)
                let userInfo = ["server_name": server.name!]
                NotificationCenter.default.post(name: Notifications.serverDeletedNoticiation, object: nil, userInfo: userInfo)
            }
        } catch {
            print("Error fetching servers!")
        }
        
        dataStack.drop()
        server = nil
        library = nil
    }
    
    func isWifiConnected() -> Bool {
        return reachability.isReachableViaWiFi
    }
    
    func loadSavedData() {
        let defaults = UserDefaults.standard
        let serverName = defaults.object(forKey: serverKey) as? String
        let libraryId = defaults.object(forKey: libraryKey) as? String
        
        if serverName != nil {
            let request: NSFetchRequest<Server> = Server.fetchRequest()
            request.predicate = NSPredicate(format: "\(ServerTable.nameColumnName) = %@", serverName!)
            dataStack.performInNewBackgroundContext {
                context in
                
                do {
                    let servers = try context.fetch(request)
                    if servers.count > 0 {
                        self.server = servers[0]
                    }
                } catch {
                    print("error fetching saved server!")
                }
            }
        }
        
        if libraryId != nil {
            let request: NSFetchRequest<Library> = Library.fetchRequest()
            request.predicate = NSPredicate(format: "\(ServerTable.nameColumnName) = %@", serverName!)
            dataStack.performInNewBackgroundContext {
                context in
                
                do {
                    let libraries = try context.fetch(request)
                    if libraries.count > 0 {
                        self.library = libraries[0]
                    }
                } catch {
                    print("error fetching saved server!")
                }
            }
        }
        
    }
    
    func deleteFiles(of server: Server) {
        let request: NSFetchRequest<Song> = Song.fetchRequest()
        request.predicate = NSPredicate(format: "\(LibraryTable.serverColumnName).\(ServerTable.nameColumnName) = %@", server.name!)
        do {
            let songs = try dataStack.mainContext.fetch(request)
            let fileManager = FileManager.default
            for song in songs {
                if let file = song.filename {
                    do {
                        try fileManager.removeItem(atPath: file)
                    } catch {
                        print("Error deleting song file!")
                    }
                }
            }
        } catch {
            print("error fetching songs of server!")
        }
    }
    
    // MARK: - Core Data stack
    // no PersistenceContext because I want to support iOS 9
/*
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cadiridris.coreDataTemplate" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
*/
    func saveContext () {
        if dataStack.mainContext.hasChanges {
            do {
                try dataStack.mainContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}

