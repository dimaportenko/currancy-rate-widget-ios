//
//  Private_Exchange.swift
//  Private Exchange
//
//  Created by Dmitriy Portenko on 08.05.2023.
//

import WidgetKit
import SwiftUI
import Intents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currencyRates: [CurrencyRate]?
    let configuration: ConfigurationIntent
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), currencyRates: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let currentDate = Date()
        CurrencyRateFetcher.shared.fetchRates { currencyRates in
            let entry = SimpleEntry(date: currentDate, currencyRates: currencyRates, configuration: configuration)
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        CurrencyRateFetcher.shared.fetchRates { currencyRates in
            if let rates = currencyRates {
                DispatchQueue.main.async {
                    CoreDataManager.shared.saveCurrencyRates(rates)
                }
            }
        
            let entry = SimpleEntry(date: currentDate, currencyRates: currencyRates, configuration: configuration)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 60, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct Private_ExchangeEntryView : View {
    var entry: Provider.Entry
    
    func roundedRateValue(_ rateValue: String) -> String {
        if let value = Double(rateValue) {
            return String(format: "%.2f", value)
        }
        return rateValue
    }
    
    func currencySymbol(for code: String) -> String {
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
    
    private func textColor(for rate: CurrencyRate) -> Color {
        if rate.ccy == "USD" {
            if let buy = Double(rate.buy), let sale = Double(rate.sale) {
                let average = (buy + sale) / 2
                return average > 37.5 ? .green : .red
            }
        }
        return .primary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rates")
                .font(.headline)
            Spacer()
            if let currencyRates = entry.currencyRates {
                ForEach(currencyRates, id: \.ccy) { rate in
                    HStack {
                        Text("\(currencySymbol(for: rate.ccy))")
                            .font(.subheadline)
                        Spacer()
                        Text("\(roundedRateValue(rate.buy)) / \(roundedRateValue(rate.sale))")
                            .foregroundColor(textColor(for: rate)).font(.footnote)
                    }
                }
            } else {
                Text("Failed to fetch currency rates")
                    .font(.footnote)
            }
        }
        .padding()
    }
}

struct Private_Exchange: Widget {
    let kind: String = "Private_Exchange"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Private_ExchangeEntryView(entry: entry)
        }
        .configurationDisplayName("Currency Rate Widget")
        .description("This widget displays the latest currency exchange rates.")
    }
}

struct Private_Exchange_Previews: PreviewProvider {
    static var previews: some View {
        Private_ExchangeEntryView(entry: SimpleEntry(date: Date(), currencyRates: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
