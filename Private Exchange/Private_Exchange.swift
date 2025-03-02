//
//  Private_Exchange.swift
//  Private Exchange
//
//  Created by Dmitriy Portenko on 08.05.2023.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData
import Combine

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currencyRates: [CurrencyRate]?
    let dashboardTotal: TotalAmountResponse?
    let configuration: ConfigurationIntent
}

struct Provider: IntentTimelineProvider {
    private let dashboardService = DashboardService.shared
    private let cancellableStorage = CancellableStorage()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), currencyRates: nil, dashboardTotal: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let currentDate = Date()
        
        // Try to fetch fresh dashboard data first
        fetchLatestDashboardData { dashboardTotal in
            // Fetch currency rates
            CurrencyRateFetcher.shared.fetchRates { currencyRates in
                let entry = SimpleEntry(
                    date: currentDate,
                    currencyRates: currencyRates,
                    dashboardTotal: dashboardTotal,
                    configuration: configuration
                )
                completion(entry)
            }
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        
        print("getTimeline")
        // Try to fetch fresh dashboard data first
        fetchLatestDashboardData { dashboardTotal in
            // Fetch currency rates
            CurrencyRateFetcher.shared.fetchRates { currencyRates in
                if let rates = currencyRates {
                    DispatchQueue.main.async {
                        CoreDataManager.shared.saveCurrencyRates(rates)
                    }
                }
                
                let entry = SimpleEntry(
                    date: currentDate,
                    currencyRates: currencyRates,
                    dashboardTotal: dashboardTotal,
                    configuration: configuration
                )
                let nextUpdate = Calendar.current.date(byAdding: .second, value: 20, to: currentDate)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
    
    // Helper method to fetch the latest dashboard data with fallback to local storage
    private func fetchLatestDashboardData(completion: @escaping (TotalAmountResponse?) -> Void) {
        let calendar = Calendar.current
        let currentDate = Date()
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate) - 1
        
        // First check if authentication is possible
        guard dashboardService.isAuthenticated() else {
            print("Widget: No authentication token available, using local data only")
            let localData = self.dashboardService.getLocalTotalAmount(year: year, month: month)
            completion(localData)
            return
        }
        
        // Try to get authenticated data from the service
        print("Widget: Start fetching data from API with authentication...")
        dashboardService.fetchTotalAmount(year: year, month: month)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    // Successfully got data from API, it's handled in receiveValue
                    print("Widget: Successfully got data from API")
                    break
                case .failure(let error):
                    // On failure, fall back to local data
                    print("Widget: API call failed: \(error), falling back to local data")
                    let localData = self.dashboardService.getLocalTotalAmount(year: year, month: month)
                    completion(localData)
                }
            }, receiveValue: { response in
                // Got fresh data from API
                print("Widget: Received data from API: \(response)")
                completion(response)
            })
            .store(in: &cancellableStorage.cancellables)
        
        // Add a fallback timer in case the API call takes too long
//        DispatchQueue.main.asyncAfter(deadline: .now() + 40.0) {
//            // If we haven't received a response yet, use local data
//            if !self.cancellableStorage.cancellables.isEmpty {
//                print("Widget: API call timed out, falling back to local data")
//                self.cancellableStorage.cancellables.removeAll()
//                let localData = self.dashboardService.getLocalTotalAmount(year: year, month: month)
//                completion(localData)
//            }
//        }
    }
}

// Add a reference type wrapper for cancellables
class CancellableStorage {
    var cancellables = Set<AnyCancellable>()
}

struct Private_ExchangeEntryView : View {
    var entry: Provider.Entry
    
    private func textColor(for rate: CurrencyRate) -> Color {
        let difference = CoreDataManager.shared.rateDifference(for: rate.ccy)
        return difference > 0 ? .green : (difference < 0 ? .red : .primary)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let dashboardTotal = entry.dashboardTotal {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DashboardUtils.formatCurrency(dashboardTotal.totalAmount))
                        .font(.system(size: 16, weight: .bold))
                    
                    HStack {
                        Text("\(DashboardUtils.formatMonth(dashboardTotal.month)), \(dashboardTotal.year)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.bottom, 10)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Currency rates section
            if let currencyRates = entry.currencyRates {
                ForEach(currencyRates, id: \.ccy) { rate in
                    HStack {
                        Text("\(Utils.currencySymbol(for: rate.ccy))")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Utils.roundedRateValue(rate.buy)) / \(Utils.roundedRateValue(rate.sale))")
                            .foregroundColor(textColor(for: rate)).font(.footnote)
                    }
                }
            } else {
                Text("Failed to fetch currency rates")
                    .font(.footnote)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct Private_Exchange: Widget {
    let kind: String = "Private_Exchange"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Private_ExchangeEntryView(entry: entry)
        }
        .configurationDisplayName("Currency & Total Widget")
        .description("This widget displays currency rates and total amount from your dashboard.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Private_Exchange_Previews: PreviewProvider {
    static var previews: some View {
        Private_ExchangeEntryView(entry: SimpleEntry(
            date: Date(),
            currencyRates: nil,
            dashboardTotal: TotalAmountResponse(totalAmount: 123456, year: 2023, month: 5),
            configuration: ConfigurationIntent())
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
