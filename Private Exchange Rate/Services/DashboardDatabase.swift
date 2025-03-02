//
//  DashboardDatabase.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation
import CoreData

class DashboardDatabase {
    static let shared = DashboardDatabase()
    
    private init() {}
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CurrencyRateModel")
        let groupID = "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            let storeURL = url.appendingPathComponent("CurrencyRateModel.sqlite")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save TotalAmount
    
    func saveTotalAmount(_ amount: Double, year: Int, month: Int) {
        // Clean up any existing data for the same year/month
        cleanupTotalAmount(year: year, month: month)
        
        let entity = NSEntityDescription.entity(forEntityName: "DashboardTotalAmount", in: context)!
        let totalAmount = NSManagedObject(entity: entity, insertInto: context)
        
        totalAmount.setValue(amount, forKey: "amount")
        totalAmount.setValue(year, forKey: "year")
        totalAmount.setValue(month, forKey: "month")
        totalAmount.setValue(Date(), forKey: "lastUpdated")
        
        saveContext()
    }
    
    // MARK: - Fetch TotalAmount
    
    func fetchTotalAmount(year: Int? = nil, month: Int? = nil) -> TotalAmountResponse? {
        // If specific year/month requested, use that
        // Otherwise, use current month/year
        let calendar = Calendar.current
        let currentDate = Date()
        let fetchYear = year ?? calendar.component(.year, from: currentDate)
        let fetchMonth = month ?? calendar.component(.month, from: currentDate) - 1
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DashboardTotalAmount")
        fetchRequest.predicate = NSPredicate(format: "year == %d AND month == %d", fetchYear, fetchMonth)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let result = results.first {
                let amount = result.value(forKey: "amount") as! Double
                let year = result.value(forKey: "year") as! Int
                let month = result.value(forKey: "month") as! Int
                
                return TotalAmountResponse(totalAmount: amount, year: year, month: month)
            }
            return nil
        } catch {
            print("Error fetching total amount: \(error)")
            return nil
        }
    }
    
    // MARK: - Clean up
    
    private func cleanupTotalAmount(year: Int, month: Int) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DashboardTotalAmount")
        fetchRequest.predicate = NSPredicate(format: "year == %d AND month == %d", year, month)
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
        } catch {
            print("Error cleaning up total amount data: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
} 