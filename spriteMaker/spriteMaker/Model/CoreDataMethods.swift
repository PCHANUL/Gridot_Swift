//
//  CoreDataMethods.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/08/16.
//

import UIKit
import CoreData

class CoreData: NSObject {
    let context: NSManagedObjectContext!
    var items: [Item]
    
    override init() {
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        items = []
        super.init()
        retriveData()
        
        // create first data
        if (items.count == 0) {
            createData(title: "", data: "")
        }
    }
    
    func retriveData(callback: (() -> Void)? = nil) {
        do {
            self.items = try self.context.fetch(Item.fetchRequest())
            DispatchQueue.main.async {
                if ((callback) != nil) {
                    callback!()
                }
            }
        }
        catch let error as NSError {
            print("Failed to get data. \(error), \(error.userInfo)")
        }
    }
    
    func createData(title: String, data: String) {
        let newEntity = Item(context: self.context)
        newEntity.title = title
        newEntity.data = data
        saveData()
    }
    
    func deleteData(index: Int) {
        let itemToRemove = self.items[index]
        self.context.delete(itemToRemove)
        saveData()
    }
    
    func updateData(index: Int, title: String, data: String) {
        let itemToUpdate = self.items[index]
        itemToUpdate.title = title
        itemToUpdate.data = data
        saveData()
    }
    
    func saveData() {
        do {
            try self.context.save()
        }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        retriveData()
    }
}


