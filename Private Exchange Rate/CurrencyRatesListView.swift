//
//  CurrencyRatesListView.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 09.05.2023.
//

import SwiftUI

struct CurrencyRatesListView: View {
    @State private var storedRates: [StoredCurrencyRate] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func loadData() {
        storedRates = CoreDataManager.shared.fetchStoredCurrencyRates()
    }
    
    var body: some View {
        NavigationView {
            List(storedRates, id: \.objectID) { rate in
                ForEach(storedRates.filter { $0.ccy == "USD" }, id: \.self) { rate in
                    HStack {
                        Text("\(Utils.roundedRateValue(rate.buy ?? "")) / \(Utils.roundedRateValue(rate.sale ?? ""))")
//                        Spacer()
//                        Text("\(Utils.currencySymbol(for: rate.ccy ?? ""))")
                        Spacer()
                        if let timestamp = rate.timestamp {
                            Text("\(dateFormatter.string(from: timestamp))")
                        }                    }
                }
            }
            .navigationTitle("Stored Currency Rates")
            .onAppear(perform: loadData)
        }
    }
}

struct CurrencyRatesListView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyRatesListView()
    }
}
