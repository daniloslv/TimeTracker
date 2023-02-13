//
//  App.swift
//  TimeTracker
//
//  Created by Danilo Souza on 04/02/23.
//

import ComposableArchitecture
import SwiftUI

struct AppReducer: ReducerProtocol {
  @Dependency(\.mainQueue) var mainQueue

  struct State: Equatable {
    var timeEntryList: TimeEntryList.State
  }

  enum Action: Equatable {
    case listAction(TimeEntryList.Action)
    case persistenceAction(PersistenceReducer.Action)
    case onAppear
  }

  private enum CommitUpdateDescriptionID {}

  var body: some ReducerProtocol<State, Action> {
    Scope(state: \.timeEntryList, action: /Action.listAction) {
      TimeEntryList()
    }
    Scope(state: \.timeEntryList, action: /Action.persistenceAction) {
      PersistenceReducer()
    }
    Reduce { _, action in
      switch action {
      case let .listAction(listAction):
        switch listAction {
        case .createNew,
             .removeAll,
             .timeTracking(id: _, action: .remove),
             .timeTracking(id: _, action: .updateDescription),
             .timeTracking(id: _, action: .updateStatus),
             .timeTracking(id: _, action: .toggleStatus):
          return .run { send in
            try await mainQueue.sleep(for: 0.5)
            await send(.persistenceAction(.saveEntries))
          }
          .cancellable(id: CommitUpdateDescriptionID.self, cancelInFlight: true)
        default:
          return .none
        }

      case let .persistenceAction(.loadEntriesDidFinish(data)):
        return .send(.listAction(.loadDataSuccess(data)))

      case .onAppear:
        return .send(.persistenceAction(.loadEntries))

      default:
        return .none
      }
    }
  }
}

@main
struct TimeTrackerApp: App {
  let store = StoreOf<AppReducer>(
    initialState: AppReducer.State(timeEntryList: TimeEntryList.State(entries: [])),
    reducer: AppReducer()
  )

  var body: some Scene {
    WindowGroup {
      HomeView(
        store: store.scope(
          state: \.timeEntryList,
          action: AppReducer.Action.listAction
        )
      )
      .onAppear { ViewStore(self.store).send(.onAppear) }
    }
  }
}
