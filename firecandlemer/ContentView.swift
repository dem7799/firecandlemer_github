//
//  ContentView.swift
//  firecandlemer
//
//  Created by Dmitriy on 04.09.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var revenueCatModel: RevenueCatModel
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(RevenueCatModel())
}
