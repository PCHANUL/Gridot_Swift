//
//  Item+CoreDataProperties.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/08/11.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var title: String?
    @NSManaged public var data: String?

}

extension Item : Identifiable {

}