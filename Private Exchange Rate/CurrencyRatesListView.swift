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
        //
        
//        CurrencyRateFetcher.shared.fetchRates { currencyRates in
//            if let rates = currencyRates {
//                DispatchQueue.main.async {
//                    CoreDataManager.shared.saveCurrencyRates(rates)
//                }
//            }
//        }
    }
    
    var body: some View {
        NavigationView {
            List(storedRates, id: \.objectID) { rate in
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(rate.ccy ?? "") to \(rate.base_ccy ?? "")")
                        Spacer()
                        Text("\(rate.buy ?? "") / \(rate.sale ?? "")")
                    }
                    if let timestamp = rate.timestamp {
                        Text("Timestamp: \(dateFormatter.string(from: timestamp))")
                    }
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
