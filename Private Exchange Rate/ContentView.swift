//
//  ContentView.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 08.05.2023.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CurrencyRatesListView()
                .tabItem {
                    Label("Rates", systemImage: "dollarsign.circle")
                }
                .tag(0)
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }
                .tag(1)
        }
        .onAppear {
            // Tab Bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Add shadow to top edge
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)
            appearance.shadowImage = UIImage.shadow(with: CGSize(width: UIScreen.main.bounds.width, height: 0.5), 
                                                   radius: 2, 
                                                   color: UIColor.black.withAlphaComponent(0.3))
            
            // Tab bar items appearance when selected
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor.systemGray
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
            itemAppearance.selected.iconColor = UIColor.label
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.label]
            
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
