//
//  DashboardUtils.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation
import SwiftUI

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
    
    /// Constructs a current date-based period string (e.g., "June 2023")
    static func currentPeriodString() -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate) - 1
        
        return "\(formatMonth(month)) \(year)"
    }
} 