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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currencyRates: [CurrencyRate]?
    let dashboardTotal: TotalAmountResponse?
    let configuration: ConfigurationIntent
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), currencyRates: nil, dashboardTotal: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let currentDate = Date()
        
        // Fetch currency rates
        CurrencyRateFetcher.shared.fetchRates { currencyRates in
            // Fetch dashboard total
            let container = CoreDataManager.shared.persistentContainer
            let dashboardTotal = DashboardUtils.fetchDashboardTotal(from: container.viewContext)
            
            let entry = SimpleEntry(
                date: currentDate,
                currencyRates: currencyRates,
                dashboardTotal: dashboardTotal,
                configuration: configuration
            )
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        
        // Fetch currency rates
        CurrencyRateFetcher.shared.fetchRates { currencyRates in
            if let rates = currencyRates {
                DispatchQueue.main.async {
                    CoreDataManager.shared.saveCurrencyRates(rates)
                }
            }
            
            // Fetch dashboard total
            let container = CoreDataManager.shared.persistentContainer
            let dashboardTotal = DashboardUtils.fetchDashboardTotal(from: container.viewContext)
        
            let entry = SimpleEntry(
                date: currentDate,
                currencyRates: currencyRates,
                dashboardTotal: dashboardTotal,
                configuration: configuration
            )
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 60, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct Private_ExchangeEntryView : View {
    var entry: Provider.Entry
    
    private func textColor(for rate: CurrencyRate) -> Color {
        let difference = CoreDataManager.shared.rateDifference(for: rate.ccy)
        return difference > 0 ? .green : (difference < 0 ? .red : .primary)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        // Convert from cents to dollars
        let dollarAmount = amount / 100.0
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "UAH" // Change as needed
        
        return formatter.string(from: NSNumber(value: abs(dollarAmount))) ?? "$\(abs(dollarAmount))"
    }
    
    private func formatMonth(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        var components = DateComponents()
        components.month = month + 1 // Adjust month for correct display
        
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        
        return "\(month + 1)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Display dashboard total if available
            if let total = entry.dashboardTotal {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DashboardUtils.formatMonth(total.month))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(DashboardUtils.formatCurrency(total.totalAmount))
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            } else {
                Text("Failed to fetch dashboard total")
                    .font(.footnote)
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
