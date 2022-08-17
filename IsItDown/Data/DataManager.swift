//
//  DataManager.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import CoreData
import Foundation

final class PersistenceProvider {
    enum StoreType {
        case inMemory, persisted
    }

    static var managedObjectModel: NSManagedObjectModel = {
        let bundle = Bundle(for: PersistenceProvider.self)
        guard let url = bundle.url(forResource: "Data", withExtension: "momd") else {
            fatalError("Failed to locate momd file for Checklist")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load momd file for Checklist")
        }
        return model
    }()

    var persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }

    var documentDir: URL {
        let documentDir = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        return documentDir!
    }

    static let `default`: PersistenceProvider = PersistenceProvider()
    init(storeType: StoreType = .persisted) {
        persistentContainer = NSPersistentContainer(name: "Data", managedObjectModel: Self.managedObjectModel)

        if storeType == .inMemory {
            persistentContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        persistentContainer.loadPersistentStores { _, error in
            self.context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            self.context.automaticallyMergesChangesFromParent = true

            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

    }
    

}

extension PersistenceProvider {
    
     
     var allAssets: [Asset]{
         get {
             let c = getAssets()
             return c
         }
     }
     
    func clearDB() {
        // List of multiple objects to delete
        let assets: [Asset] = getAssets()

        // Get a reference to a managed object context
        let context = persistentContainer.viewContext

        // Delete multiple objects
        for asset in assets {
            delete(asset)
        }

        // Save the deletions to the persistent store
        try? context.save()
    }
   

    func getAssets() -> [Asset] {
        let fetchRequest: NSFetchRequest = Asset.fetchRequest()
        fetchRequest.sortDescriptors = []
        do {
            let result = try context.fetch(fetchRequest)
            return result
        } catch {
            return []
        }
    }

   
    func delete(_ item: Asset) {
        context.delete(item)
        try? context.save()
    }
}

