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
    
    private func textColor(for rate: CurrencyRate) -> Color {
        let difference = CoreDataManager.shared.rateDifference(for: rate.ccy)
        return difference > 0 ? .green : (difference < 0 ? .red : .primary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rates")
                .font(.headline)
            Spacer()
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
        .containerBackground(.secondary, for: .widget)
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
