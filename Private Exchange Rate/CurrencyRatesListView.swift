//
//  CurrencyRatesListView.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 09.05.2023.
//

import SwiftUI

struct CurrencyRatesListView: View {
    @State private var storedRates: [StoredCurrencyRate] = []
    @State private var selectedCurrency = "USD"  // State variable for the selected currency
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        return formatter
    }()
    
    private func loadData() {
        storedRates = CoreDataManager.shared.fetchStoredCurrencyRates(ccy: selectedCurrency)
    }
    
    private func refetch() {
        CurrencyRateFetcher.shared.fetchRates { currencyRates in
            if let rates = currencyRates {
                DispatchQueue.main.async {
                    CoreDataManager.shared.saveCurrencyRates(rates)
                    loadData()
                }
            }
        }
    }
    
    private func differenceText(currentValue: String?, nextValue: String?) -> some View {
        guard let current = Double(currentValue ?? ""),
              let next = Double(nextValue ?? ""),
              current != next else {
            return Text("±0")
        }
        
        let diff = current - next
        return Text(String(format: "%@%.2f", diff > 0 ? "+" : (diff < 0 ? "" : "±"), diff))
            .foregroundColor(diff > 0 ? .green : (diff < 0 ? .red : Color.primary))
    }
    
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Currency", selection: $selectedCurrency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedCurrency) { newValue in
                    storedRates = CoreDataManager.shared.fetchStoredCurrencyRates(ccy: newValue)
                }
                
                List {
                    ForEach(Array(storedRates.enumerated()), id: \.element) { index, rate in
                        GeometryReader { geometry in
                            HStack {
                                if let timestamp = rate.timestamp {
                                    Text("\(dateFormatter.string(from: timestamp))").frame(width: geometry.size.width / 9 * 5)
                                }
                                Spacer()
                                
                                VStack {
                                    HStack {
                                        Text("\(Utils.roundedRateValue(rate.buy ?? ""))").frame(width: geometry.size.width / 9 * 2)
                                        
                                        if storedRates.count - index > 1 {
                                            let nextRate = storedRates[index + 1]
                                            differenceText(currentValue: rate.buy, nextValue: nextRate.buy).frame(width: geometry.size.width / 9 * 2)
                                        } else {
                                            differenceText(currentValue: rate.buy, nextValue: nil).frame(width: geometry.size.width / 9 * 2)
                                        }
                                    }
                                    HStack {
                                        Text("\(Utils.roundedRateValue(rate.sale ?? ""))").frame(width: geometry.size.width / 9 * 2)
                                        
                                        if storedRates.count - index > 1 {
                                            let nextRate = storedRates[index + 1]
                                            differenceText(currentValue: rate.sale, nextValue: nextRate.sale).frame(width: geometry.size.width / 9 * 2)
                                        } else {
                                            differenceText(currentValue: rate.sale, nextValue: nil).frame(width: geometry.size.width / 9 * 2)
                                        }
                                    }
                                }.frame(width: geometry.size.width / 9 * 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stored USD rates")
            .onAppear(perform: loadData)
            .refreshable {
                refetch()
            }
        }
        
    }
}

struct CurrencyRatesListView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyRatesListView()
    }
}
