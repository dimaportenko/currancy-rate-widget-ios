//
//  DashboardUtils.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation
import SwiftUI
import CoreData

/// Shared utilities for dashboard functionality across main app and widget extension
struct DashboardUtils {
    /// Formats currency from cents to display value with proper currency symbol
    static func formatCurrency(_ amount: Double, currencyCode: String = "UAH") -> String {
        // Convert from cents to dollars
        let dollarAmount = amount / 100.0
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        
        return formatter.string(from: NSNumber(value: abs(dollarAmount))) ?? "$\(abs(dollarAmount))"
    }
    
    /// Formats month number to month name
    static func formatMonth(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        var components = DateComponents()
        components.month = month + 1 // Adjust month for correct display
        
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        
        return "\(month + 1)"
    }
    
    /// Creates a date formatter for dashboard date displays
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    /// Fetches total amount data from CoreData
    static func fetchDashboardTotal(from context: NSManagedObjectContext) -> TotalAmountResponse? {
        let calendar = Calendar.current
        let currentDate = Date()
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate) - 1
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DashboardTotalAmount")
        fetchRequest.predicate = NSPredicate(format: "year == %d AND month == %d", year, month)
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
            print("Error fetching dashboard total amount: \(error)")
            return nil
        }
    }
} 
