//
//  MenuItemTableViewController.swift
//  CloudKitTask
//
//  Created by Robert Berry on 4/10/18.
//  Copyright © 2018 Robert Berry. All rights reserved.
//

import UIKit
import CloudKit 

class MenuItemTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var restaurant: Restaurant?
    
    struct Storyboard {
        
        static let menuItemCell = "MenuItemCell"
    }
    
    // Creates reference to iCloud public database.
    
    let database = CKContainer.default().publicCloudDatabase
    
    // Holds the menu items that have been loaded to CloudKit.
    
    var menuItems = [CKRecord]()
    
    // Control that refreshes the table view's contents.
    
    var refresh: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate the UIRefreshControl that was previously created.

        refresh = UIRefreshControl()
        
        refresh.attributedTitle = NSAttributedString(string: "Pull to load menu items.")
        
        // loadMenuItems() is called when the value of the control is changed, in this case when the table view is pulled down.
        
        refresh.addTarget(self, action: #selector(MenuItemTableViewController.loadMenuItems), for: .valueChanged)
        
        // Add control as subview of the table view.
        
        tableView.addSubview(refresh)
        
        // Loads menu items from the database.
        
        loadMenuItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Adds title to navigation item. 
        
        navigationItem.title = restaurant?["name"] as? String ?? "Restaurants" 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Action Methods
    
    @IBAction func addMenuItem(_ sender: Any) {
        
        // Creates message object for alert controller using string interpolation. 
        
        var message = "Please enter new menu item" 
        
        if let restaurantName = restaurant?[RestaurantProperties.name] as? String {
            
            message = message + " for \(restaurantName)"
        }
        
        // Creates alert controller.
        
        let alert = UIAlertController(title: "New Menu Item", message: message, preferredStyle: .alert)
        
        // Adds textfields to alert controller.
        
        alert.addTextField { (textField: UITextField) in
            
            textField.placeholder = "Please enter name of menu item."
        }
        
        // Adds UIAlertAction to alert controller that will save new menu item. 
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action: UIAlertAction) in
            
            // Returns first text field element of alert controller.
            
            let textField = alert.textFields?.first
            
            // Verify the textField does not contain an empty string, and then execute the if-statement.
            
            if textField?.text != "" {
                
                // Create CKRecord object and set the recordType to MenuItems. 
                
                let newMenuItem = CKRecord(recordType: MenuItemProperties.recordType)
                
                // Creates cloud kit reference to Restaurant record type. 
                
                let restaurantReference = CKReference(recordID: (self.restaurant?.recordID)!, action: CKReferenceAction.deleteSelf)
                
                // Text is saved in "name" field.
                
                newMenuItem[MenuItemProperties.name] = textField?.text as CKRecordValue?
                
                // Sets the restaurant menu item property to the previously set restaurant. 
                
                newMenuItem[MenuItemProperties.restaurant] = restaurantReference
                
                // Save record to public iCloud database that was previously declared if there are no errors.
                
                self.database.save(newMenuItem, completionHandler: { (record: CKRecord?, error: Error?) in
                    
                    if error == nil {
                        
                        print("New menu item has been saved.")
                        
                        DispatchQueue.main.async(execute: {
                            
                            self.tableView.beginUpdates()
                            
                            // Adds new menu item to cloud kit record at index path 0.
                            
                            self.menuItems.insert(newMenuItem, at: 0)
                            
                            let indexPath = IndexPath(row: 0, section: 0)
                            
                            self.tableView.insertRows(at: [indexPath], with: .top)
                            
                            self.tableView.endUpdates()
                        })
                        
                    } else {
                        
                        print("Error: \(error.debugDescription)")
                    }
                })
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func loadMenuItems() {
        
        // Creates cloud kit reference to Restaurants record type.
        
        let predicateArguments = CKReference(recordID: (restaurant?.recordID)!, action: CKReferenceAction.deleteSelf)
        
        // Creates a CKQuery object, which acts like a filter for searching and sorting records.
        
        // The NSPredicate class defines the conditions of a search.
        
        let query = CKQuery(recordType: MenuItemProperties.recordType, predicate: NSPredicate(format: "restaurant == %@", predicateArguments))
        
        // Determines how the query results will be sorted.
        
        query.sortDescriptors = [NSSortDescriptor(key: MenuItemProperties.name, ascending: true)]
        
        // Perform query.
        
        database.perform(query, inZoneWith: nil) { (results: [CKRecord]?, error: Error?) in
            
            if let menuItems = results {
                
                self.menuItems = menuItems
                
                DispatchQueue.main.async(execute: {
                   
                    self.tableView.reloadData()
                    
                    // Tells the control that the refresh operation has ended.
                    
                    self.refresh.endRefreshing()
                })
            }
        }
    }
    
    // Method deletes menuItem. 
    
    func deleteMenuItem(_ menuItem: CKRecord) {
        
        database.delete(withRecordID: menuItem.recordID, completionHandler: {(recordID, error) -> Void in
            
            if let errors = error {
                print("Error:\(errors.localizedDescription)")
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.menuItemCell, for: indexPath)
       
        let menuItem = menuItems[indexPath.row]
        
        cell.textLabel?.text = menuItem[MenuItemProperties.name] as? String
        
        return cell
    }
    
    // Override to support editing the table view.
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            deleteMenuItem(menuItems[indexPath.row])
            
            menuItems.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            tableView.reloadData()
        }
    }
}
