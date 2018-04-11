//
//  RestaurantTableViewController.swift
//  CloudKitTask
//
//  Created by Robert Berry on 4/10/18.
//  Copyright © 2018 Robert Berry. All rights reserved.
//

// restaurants

import UIKit
import CloudKit

class RestaurantTableViewController: UITableViewController {
    
    // MARK: Properties
    
    struct Storyboard {
        
        static let restaurantCell = "RestaurantCell" 
        
        static let menuItemsSegue = "MenuItemsSegue"
    }
    
    // Holds the restaurants that have been loaded to CloudKit.
    
    var restaurants = [CKRecord]()
    
    // Control that refreshes the table view's contents.
    
    var refresh: UIRefreshControl!
    
    // Creates reference to iCloud public database. 
    
    let database = CKContainer.default().publicCloudDatabase

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate the UIRefreshControl that was previously created.

        refresh = UIRefreshControl()
       
        refresh.attributedTitle = NSAttributedString(string: "Pull to load restaurants.")
        
        // loadRestaurants() is called when the value of the control is changed, in this case when the table view is pulled down. 
       
        refresh.addTarget(self, action: #selector(RestaurantTableViewController.loadRestaurants), for: .valueChanged)
        
        // Add control as subview of the table view.
        
        tableView.addSubview(refresh)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Loads restaurants from the database. 
        
        loadRestaurants()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return restaurants.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.restaurantCell, for: indexPath)

        // Configure the cell...

        let restaurant = restaurants[indexPath.row]
        
        cell.textLabel?.text = restaurant[RestaurantProperties.name] as? String
        
        return cell
    }
    
    // Override to support editing the table view.
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
       
        if editingStyle == .delete {
            
            // Delete the row from the data source
            
            deleteRestaurant(restaurants[indexPath.row])
            
            restaurants.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            tableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Storyboard.menuItemsSegue, let destinationViewController = segue.destination as? MenuItemTableViewController, let indexPath = self.tableView.indexPathForSelectedRow {
            
            destinationViewController.restaurant = restaurants[indexPath.row] 
        }
    }
    
    // MARK: Action Methods
    
    @IBAction func addRestaurant(_ sender: Any) {
        
        // Creates alert controller.
        
        let alert = UIAlertController(title: "New Restaurant", message: "Please enter restaurant and menu item information.", preferredStyle: .alert)
        
        // Adds textfields to alert controller.
        
        alert.addTextField { (textField: UITextField) in
            
            // Provides placeholder text for textField.
            
            textField.placeholder = "Please enter restaurant name."
        }
        
        alert.addTextField { (textField: UITextField) in
            
            textField.placeholder = "Please enter menu item name." 
        }
        
        // Adds UIAlertAction to alert controller.
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action: UIAlertAction) in
            
            // Returns first text field element of alert controller.
            
            let restaurantTextField = alert.textFields?.first
            
            // Returns text field element at index 1 of alert controller. 
            
            let menuItemTextField = alert.textFields?[1]
            
            // Verify the textField does not contain an empty string, and then execute the if-statement.
            
            if restaurantTextField?.text != "" {
                
                // Create CKRecord object and set the recordType to Restaurants.
                
                let newRestaurant = CKRecord(recordType: RestaurantProperties.recordType)
                
                // Text is saved in "name" field. 
                
                newRestaurant[RestaurantProperties.name] = restaurantTextField?.text as CKRecordValue?
                
                // Save record to public iCloud database that was previously declared if there are no errors.
                
                self.database.save(newRestaurant, completionHandler: { (record: CKRecord?, error: Error?) in
                   
                    if error == nil {
                        
                        print("Restaurant saved.")
                       
                        DispatchQueue.main.async(execute: {
                            
                            self.tableView.beginUpdates()
                            
                            // Adds new restaurant to cloud kit record at index path 0.
                            
                            self.restaurants.insert(newRestaurant, at: 0)
                           
                            let indexPath = IndexPath(row: 0, section: 0)
                            
                            self.tableView.insertRows(at: [indexPath], with: .top)
                            
                            self.tableView.endUpdates()
                            
                            let menuItemName = menuItemTextField?.text ?? ""
                            
                            self.addMenuItem(menuItemName, for: newRestaurant)
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
    
    // Method adds menu item for restaurant.
    
    func addMenuItem(_ menuItemName: String, for restaurant: Restaurant) {
        
        // Verifies that a menuItemName exists.
        
        guard menuItemName.count > 0 else { return }
        
        // Creates cloud kit record for newMenuItem. 
        
        let newMenuItem = CKRecord(recordType: MenuItemProperties.recordType)
        
        // Creates cloud kit reference to Restaurants record type. 
        
        let restaurantReference = CKReference(recordID: restaurant.recordID, action: CKReferenceAction.deleteSelf)
        
        newMenuItem[MenuItemProperties.restaurant] = restaurantReference 
       
        let name = menuItemName as CKRecordValue
        
        newMenuItem[MenuItemProperties.name] = name
        
        // Saves new menu item to the cloud kit database.
        
        database.save(newMenuItem, completionHandler: {(record, error) -> Void in
            
            if let errors = error {
                
                print("Error:\(errors.localizedDescription)")
            }
        })
    }
    
    // Method loads restaurants from the iCloud.
    
    @objc func loadRestaurants() {
        
        // Creates a CKQuery object, which acts like a filter for searching and sorting records.
        
        // The NSPredicate class defines the conditions of a search.
        
        // TRUEPREDICATE is a predicate that always evaluates to true, therefore all records will match.
        
        let query = CKQuery(recordType: RestaurantProperties.recordType, predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
       
        // Determines how the query results will be sorted.
        
        query.sortDescriptors = [NSSortDescriptor(key: RestaurantProperties.name, ascending: true)]
        
        // Perform query.
        
        database.perform(query, inZoneWith: nil) { (results: [CKRecord]?, error: Error?) in
            
            if let restaurants = results {
                
                self.restaurants = restaurants
                
                DispatchQueue.main.async(execute: {
                   
                    self.tableView.reloadData()
                    
                    // Tells the control that the refresh operation has ended.
                    
                    self.refresh.endRefreshing()
                })
            }
        }
    }
    
    // Method deletes restaurant record.
    
    func deleteRestaurant(_ restaurant: CKRecord) {
       
        database.delete(withRecordID: restaurant.recordID, completionHandler: {(recordID, error) -> Void in
            
            if let errors = error {
                
                print("Error:\(errors.localizedDescription)")
            }
        })
    }
}
