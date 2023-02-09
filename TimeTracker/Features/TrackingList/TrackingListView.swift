//
//  TrackingListView.swift
//  TimeTracker
//
//  Created by Danilo Souza on 06/02/23.
//

import ComposableArchitecture
import SwiftUI

extension TrackingListView {
  struct ViewState: Equatable {
    let state: TimeEntryCollectionReducer.State
    let clearAllLabel: String

    init(state: TimeEntryCollectionReducer.State) {
      self.state = state
      clearAllLabel = "Clear all (\(state.entries.count))"
    }
  }
}

struct TrackingListView: View {
  typealias Action = TimeEntryCollectionReducer.Action

  let store: StoreOf<TimeEntryCollectionReducer>
  @ObservedObject var viewStore: ViewStore<ViewState, Action>

  init(store: StoreOf<TimeEntryCollectionReducer>) {
    self.store = store
    viewStore = ViewStore(store, observe: ViewState.init)
  }

  var body: some View {
    VStack {
      List {
        Button(viewStore.clearAllLabel) {
          viewStore.send(.removeAll, animation: .default)
        }
        .padding()
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .frame(alignment: .trailing)

        ForEachStore(
          store.scope(
            state: { $0.entries },
            action: TimeEntryCollectionReducer.Action.timeTracking
          )
        ) { TrackingCardView(store: $0).padding([.top, .bottom], 8) }
      }
      .listStyle(.automatic)
      .onAppear { viewStore.send(.startDisplayTimer) }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(
            action: {
              viewStore.send(.createNew(description: nil, status: .started), animation: .default)
            },
            label: {
              Text("Add new")
              Image(systemName: "plus")
            }
          )
        }
      }
    }
  }
}

struct TrackingList_Previews: PreviewProvider {
  static var previews: some View {
    let createdAt = Date().addingTimeInterval(-60 * 3)

    return TrackingListView(
      store: Store(
        initialState: .init(entries: [
          .init(
            entry: TrackingEntity(
              id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
              description: .description("Another Project."),
              status: .started,
              accumulatedTime: TrackingEntity.AccumulatedTime(
                total: 10,
                accumulatedSession: 10,
                startDate: createdAt
              ),
              createdAt: createdAt,
              updatedAt: createdAt
            )
          ),
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
        ]),
        reducer: TimeEntryCollectionReducer()
      )
    )
  }
}
