//
//  Utils.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 10.05.2023.
//

import Foundation

struct Utils {
    static func roundedRateValue(_ rateValue: String) -> String {
        if let value = Double(rateValue) {
            return String(format: "%.2f", value)
        }
        return rateValue
    }
    
    static func currencySymbol(for code: String) -> String {
        switch code {
        case "EUR":
            return "€"
        case "UAH":
            return "₴"
        case "USD":
            return "$"
        default:
            return code
        }
    }

}
