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
//import Private_Exchange_Rate // Import the main app module where DashboardUtils is located

// Static counter that uses UserDefaults for persistence
class RefreshTracker {
    // Store counter in UserDefaults so it persists between widget process launches
    static var timelineCounter: Int {
        get {
            let defaults = UserDefaults(
                suiteName: "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
            ) ?? UserDefaults.standard
            return defaults.integer(forKey: "widgetRefreshCounter")
        }
        set {
            let defaults = UserDefaults(
                suiteName: "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
            ) ?? UserDefaults.standard
            defaults.set(newValue, forKey: "widgetRefreshCounter")
        }
    }
    
    static var lastRefreshTime: Date {
        get {
            let defaults = UserDefaults(
                suiteName: "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
            ) ?? UserDefaults.standard
            return defaults.object(forKey: "widgetLastRefreshTime") as? Date ?? Date()
        }
        set {
            let defaults = UserDefaults(
                suiteName: "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
            ) ?? UserDefaults.standard
            defaults.set(newValue, forKey: "widgetLastRefreshTime")
        }
    }
    
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let refreshCount: Int
    let refreshTime: String
    let isPlaceholder: Bool
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationIntent(),
            refreshCount: 0,
            refreshTime: "N/A",
            isPlaceholder: true
        )
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let currentDate = Date()
        
        // Increment the counter for the snapshot too
        RefreshTracker.timelineCounter += 1
        let count = RefreshTracker.timelineCounter
        let timeString = RefreshTracker.formatter.string(from: currentDate)
        
        print("Widget: getSnapshot called #\(count) at \(timeString)")
        
        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            refreshCount: count,
            refreshTime: timeString,
            isPlaceholder: false
        )
        completion(entry)
    }


     func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
//    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        
        // Record when getTimeline was last called
        let lastTime = RefreshTracker.lastRefreshTime
        let timeSinceLastRefresh = currentDate.timeIntervalSince(lastTime)
        
        // Increment the counter each time getTimeline is called
        RefreshTracker.timelineCounter += 1
        RefreshTracker.lastRefreshTime = currentDate
        
        let count = RefreshTracker.timelineCounter
        let timeString = RefreshTracker.formatter.string(from: currentDate)
        
        print("getTimeline called #\(count) at \(timeString) - \(timeSinceLastRefresh) seconds since last refresh")
        
        // Create just a single entry
        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            refreshCount: count,
            refreshTime: timeString,
            isPlaceholder: false
        )
        
        // Schedule the next refresh in 60 minutes
        let nextRefreshDate = Calendar.current.date(byAdding: .second, value: 60, to: currentDate)!
        print("Widget: Created timeline with 1 entry, next refresh scheduled at \(RefreshTracker.formatter.string(from: nextRefreshDate)) (in 60 minutes)")
        
        let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
        completion(timeline)
    }
}

struct Private_ExchangeEntryView : View {
    var entry: Provider.Entry
    // Display time when this view was rendered
    @State private var displayTime = RefreshTracker.formatter.string(from: Date())
    @State private var lastGetTimelineTime = RefreshTracker.lastRefreshTime
    
    // Calculate the time remaining to the next scheduled refresh
    private var timeToNextRefresh: String {
        let secondsUntilNextRefresh = Calendar.current.dateComponents([.second], from: Date(), to: entry.date).second ?? 0
        if secondsUntilNextRefresh > 0 {
            return "Next: \(secondsUntilNextRefresh)s"
        } else {
            return "Current"
        }
    }
    
    // Calculate time since getTimeline was last called
    private var timeSinceGetTimeline: String {
        let seconds = Int(Date().timeIntervalSince(lastGetTimelineTime))
        return "\(seconds)s ago"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Widget Test Mode")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Refresh counter and diagnostic info
            VStack(alignment: .leading, spacing: 6) {
                // First row: Refresh counter and next scheduled entry
                HStack {
                    Text("Refresh #\(entry.refreshCount)")
                        .font(.subheadline)
                    Spacer()
                    Text(timeToNextRefresh)
                        .font(.subheadline)
                }
                
                // Second row: Last getTimeline call
                HStack {
                    Text("GetTimeline:")
                        .font(.subheadline)
                    Spacer()
                    Text(timeSinceGetTimeline)
                        .font(.subheadline)
                }
                
                // Third row: Entry creation time vs view rendering time
                HStack {
                    Text("Entry: \(entry.refreshTime)")
                        .font(.subheadline)
                    Spacer()
                    Text("View: \(displayTime)")
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            Text("Widget refresh test")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
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
            configuration: ConfigurationIntent(),
            refreshCount: 0,
            refreshTime: "N/A",
            isPlaceholder: false
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
