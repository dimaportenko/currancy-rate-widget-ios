//
//  CurrencyRate.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 08.05.2023.
//

import Foundation

struct CurrencyRate: Codable {
    let ccy: String
    let base_ccy: String
    let buy: String
    let sale: String
}
