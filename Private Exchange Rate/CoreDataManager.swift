//
//  CoreDataManager.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 09.05.2023.
//

import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CurrencyRateModel")
        let groupID = "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            let storeURL = url.appendingPathComponent("CurrencyRateModel.sqlite")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func saveCurrencyRates(_ rates: [CurrencyRate]) {
        let context = persistentContainer.viewContext
        let calendar = Calendar.current

        for rate in rates {
            let request = NSFetchRequest<StoredCurrencyRate>(entityName: "StoredCurrencyRate")
            request.predicate = NSPredicate(format: "ccy == %@ AND base_ccy == %@", rate.ccy, rate.base_ccy)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = 1

            do {
                let previousRates = try context.fetch(request)

                if let previousRate = previousRates.first,
                   calendar.isDate(previousRate.timestamp ?? Date(), inSameDayAs: Date()) &&
                   previousRate.buy == rate.buy && previousRate.sale == rate.sale {
                    print("Same day and rates unchanged: \(rate.ccy) -> \(rate.base_ccy)")
                    continue
                }

                let storedRate = StoredCurrencyRate(context: context)
                storedRate.ccy = rate.ccy
                storedRate.base_ccy = rate.base_ccy
                storedRate.buy = rate.buy
                storedRate.sale = rate.sale
                storedRate.timestamp = Date()

            } catch {
                print("Failed to fetch previous currency rate: \(error)")
            }
        }

        do {
            try context.save()
            print("Currency rates saved")
        } catch {
            print("Failed to save currency rates: \(error)")
        }
    }

    func fetchStoredCurrencyRates() -> [StoredCurrencyRate] {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<StoredCurrencyRate>(entityName: "StoredCurrencyRate")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let storedRates = try context.fetch(request)
            print("Fetched stored currency rates: \(storedRates.count)")
            return storedRates
        } catch {
            print("Failed to fetch stored currency rates: \(error)")
            return []
        }
    }
}
