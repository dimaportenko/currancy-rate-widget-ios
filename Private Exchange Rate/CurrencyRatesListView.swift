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
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
    
    private func loadData() {
        storedRates = CoreDataManager.shared.fetchStoredCurrencyRates()
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(storedRates.enumerated()), id: \.element) { index, rate in
                    HStack {
                        Text("\(Utils.roundedRateValue(rate.buy ?? "")) / \(Utils.roundedRateValue(rate.sale ?? ""))")
                        //                        Spacer()
                        //                        Text("\(Utils.currencySymbol(for: rate.ccy ?? ""))")
                        Spacer()
                        if let timestamp = rate.timestamp {
                            Text("\(dateFormatter.string(from: timestamp))")
                            //                            Text("\(timestamp)")
                        }
                        Spacer()
                        if storedRates.count - index > 1 {
                            if let currentSale = Double(rate.sale ?? ""),
                               let previousSale = Double(storedRates[index + 1].sale ?? "") {
                                let diff = currentSale - previousSale
                                if diff != 0 {
                                    Text(String(format: "%@%.2f", diff > 0 ? "+" : (diff < 0 ? "-" : "±"), diff))
                                        .foregroundColor(diff > 0 ? .green : (diff < 0 ? .red : .black))
                                } else {
                                    
                                    Text("±0")
                                }
                            }
                        } else {
                            Text("±0")
                        }
                    }
                }
            }
            .navigationTitle("Stored Currency Rates")
            .onAppear(perform: loadData)
            .refreshable {
                loadData()
            }
        }
        
    }
}

struct CurrencyRatesListView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyRatesListView()
    }
}
