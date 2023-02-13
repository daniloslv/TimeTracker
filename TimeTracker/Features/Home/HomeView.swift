//
//  HomeView.swift
//  TimeTracker
//
//  Created by Danilo Souza on 06/02/23.
//

import ComposableArchitecture
import SwiftUI

extension HomeView {
  struct ViewState: Equatable {
    let trackings: IdentifiedArrayOf<TimeEntry.State>
    var pageTitle: String = "Time Tracker"

    init(state: TimeEntryList.State) {
      trackings = state.entries
    }
  }
}

struct HomeView: View {
  let store: StoreOf<TimeEntryList>
  @ObservedObject var viewStore: ViewStore<ViewState, TimeEntryList.Action>

  init(store: StoreOf<TimeEntryList>) {
    self.store = store
    viewStore = ViewStore(store.scope(state: ViewState.init))
  }

  var body: some View {
    #if os(macOS)
      NavigationStack {
        TrackingListView(store: store)
          .navigationTitle(viewStore.state.pageTitle)
      }
    #endif

    #if os(iOS)
      NavigationView {
        TrackingListView(store: store)
          .navigationTitle(viewStore.state.pageTitle)
      }
      .navigationViewStyle(.stack)
    #endif
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

    return HomeView(
      store: Store(
        initialState: .init(entries: [
          .init(
            entry: TrackingEntity(
              id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
              description: .description("My important project"),
              status: .stopped,
              accumulatedTime: TrackingEntity.AccumulatedTime(),
              createdAt: createdAt,
              updatedAt: createdAt
            )
          ),
          .init(
            entry: TrackingEntity(
              id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
              description: .description("Another Project."),
              status: .started,
              accumulatedTime: TrackingEntity.AccumulatedTime(),
              createdAt: createdAt,
              updatedAt: createdAt
            )
          ),
        ]),
        reducer: TimeEntryList()
      )
    )
  }
}
