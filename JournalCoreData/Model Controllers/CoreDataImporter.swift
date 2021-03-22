//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
  
    
    func sync(representations: [EntryRepresentation]) throws {
        let context = CoreDataStack.shared.container.newBackgroundContext()
        let identifiersToFetch = representations.compactMap({ $0.identifier })
        // Make dictionary of key value pairs to check representations against those in CD
        let representationsById = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representations))
        var entriesToCreate = representationsById
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        context.performAndWait {
            do {
                // Instead of fetching the single entry, let's fetch all of them just once
                let storeEntries = try context.fetch(fetchRequest)
                
                for entry in storeEntries {
                    guard let identifier = entry.identifier,
                          let representation = representationsById[identifier] else { continue }
                    
                    self.update(entry: entry, with: representation)
                    entriesToCreate.removeValue(forKey: identifier)
                }
                for representation in entriesToCreate.values {
                    Entry(entryRepresentation: representation, context: context)
                }
                
            } catch {
                NSLog("Error fetching entries for IDs, \(error)")
            }
        }
        try CoreDataStack.shared.save(with: context)
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
   
}
