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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var drawerContainer: MMDrawerController?
    var centerViewController: UIViewController?
    var settingsViewController: UIViewController?
    var centerNav: UINavigationController?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        centerViewController = mainStoryboard.instantiateViewController(withIdentifier: "MainViewController") as UIViewController
        
        let drawerViewController = mainStoryboard.instantiateViewController(withIdentifier: "DrawerController") as UIViewController
        
        settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "SettingsController") as UIViewController
        
        //let drawerNav = UINavigationController(rootViewController: drawerViewController)
        centerNav = UINavigationController(rootViewController: centerViewController!)
        
        drawerContainer = MMDrawerController(center: centerNav, leftDrawerViewController: drawerViewController)
        drawerContainer?.openDrawerGestureModeMask = MMOpenDrawerGestureMode.bezelPanningCenterView
        drawerContainer?.closeDrawerGestureModeMask = [MMCloseDrawerGestureMode.panningCenterView, MMCloseDrawerGestureMode.panningDrawerView, MMCloseDrawerGestureMode.tapCenterView]
        drawerContainer?.showsShadow = false
        //drawerContainer?.setDrawerVisualStateBlock(MMDrawerVisualState.slideVisualStateBlock())
        drawerContainer?.setDrawerVisualStateBlock(animateDrawer)
        
        
        let drawerButton = MMDrawerBarButtonItem(target: self, action: #selector(onDrawerButtonPressed))
        let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(onSettingsButtonPressed))
        centerViewController?.navigationItem.leftBarButtonItem = drawerButton
        centerViewController?.navigationItem.rightBarButtonItem = settingsButton
        
        window!.rootViewController = drawerContainer
        window!.makeKeyAndVisible()
        
        deleteAllData()
        addSomeData()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @objc func onDrawerButtonPressed() {
        drawerContainer?.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
    
    func onSettingsButtonPressed() {
        centerNav?.pushViewController(settingsViewController!, animated: true)
    }
    
    func animateDrawer(drawerController: MMDrawerController?, drawerSide: MMDrawerSide, percentVisible: CGFloat) {
        centerNav?.view.alpha = 1 - (percentVisible * 0.5)
        
        //do provided animation
        let block = MMDrawerVisualState.slideVisualStateBlock()
        block?(drawerController, drawerSide, percentVisible)
    }
    
    private func deleteAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
        }
        catch {
            fatalError("Could not delete data!")
        }
    }
    
    private func addSomeData() {
        let song1 = NSEntityDescription.insertNewObject(forEntityName: "Song", into: managedObjectContext) as! Song
        let song2 = NSEntityDescription.insertNewObject(forEntityName: "Song", into: managedObjectContext) as! Song
        let song3 = NSEntityDescription.insertNewObject(forEntityName: "Song", into: managedObjectContext) as! Song
        let song4 = NSEntityDescription.insertNewObject(forEntityName: "Song", into: managedObjectContext) as! Song
        
        song1.title = "Song1"
        song2.title = "Song2"
        song3.title = "Song3"
        song4.title = "Song4"
        
        song1.artist = "Artist1"
        song2.artist = "Artist2"
        song3.artist = "Artist3"
        song4.artist = "Artist1"
        
        song1.album = "Album1"
        song2.album = "Album2"
        song3.album = "Album3"
        song4.album = "Album1"
        
        saveContext()
    }
    
    
    // MARK: - Core Data stack
    // no PersistenceContext because I want to support iOS 9
    
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
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
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

