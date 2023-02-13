//
//  PersistenceReducer.swift
//  TimeTracker
//
//  Created by Danilo Souza on 10/02/23.
//

import ComposableArchitecture
import Foundation

struct PersistenceReducer: ReducerProtocol {
  @Dependency(\.persistence) var persistence
  @Dependency(\.mainQueue) var mainQueue

  typealias State = TimeEntryList.State

  enum Action: Equatable {
    case loadEntries
    case loadEntriesResponse([TrackingEntity])
    case loadEntriesDidFinish(IdentifiedArrayOf<TimeEntry.State>)
    case saveEntries
  }

  private enum CommitUpdateDescriptionID {}

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .loadEntries:
        return EffectPublisher(
          persistence.loadTrackings()
            .replaceError(with: [])
            .map(Action.loadEntriesResponse)
        )

      case let .loadEntriesResponse(loadedEntries):
        let entries = IdentifiedArrayOf(uniqueElements: loadedEntries.map(TimeEntry.State.init))
        return .send(.loadEntriesDidFinish(entries))

      case .loadEntriesDidFinish:
        return .none

      case .saveEntries:
        return EffectPublisher(
          persistence
            .saveTrackings(trackings: state.entries.map(\.entry))
            .fireAndForget()
        )
      }
    }
  }
}
