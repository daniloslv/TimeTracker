//
//  App.swift
//  TimeTracker
//
//  Created by Danilo Souza on 04/02/23.
//

import ComposableArchitecture
import SwiftUI

@main
struct TimeTrackerApp: App {
  let store = StoreOf<TimeEntryCollectionReducer>(
    initialState: TimeEntryCollectionReducer.State(entries: .init()),
    reducer: TimeEntryCollectionReducer()
  )

  var body: some Scene {
    WindowGroup {
      HomeView(store: store)
    }
  }
}
