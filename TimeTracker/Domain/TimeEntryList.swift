//
//  TimeEntryCollectionReducer.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import ComposableArchitecture
import Foundation

public struct TimeEntryList: ReducerProtocol {
  @Dependency(\.uuid) var uuidGenerator
  @Dependency(\.date) var dateGenerator
  @Dependency(\.mainQueue) var mainQueue

  public struct State: Equatable {
    public var entries: IdentifiedArrayOf<TimeEntry.State> = []
  }

  public enum Action: Equatable {
    case createNew(description: String?, status: TrackingEntity.Status)
    case loadDataSuccess(IdentifiedArrayOf<TimeEntry.State>)
    case removeAll
    case startDisplayTimer
    case stopDisplayTimer
    case refreshDisplayTimer
    case timeTracking(id: TimeEntry.State.ID, action: TimeEntry.Action)
  }

  private enum TimerTickID {}

  public var body: some ReducerProtocol<State, Action> {
    Scope(state: \.entries, action: /Action.timeTracking) {
      Reduce { state, action in
        let (id, elementAction) = action
        guard state[id: id] != nil else { return .none }
        return TimeEntry()
          .reduce(into: &state[id: id]!, action: elementAction)
          .map { action in (id, action) }
      }
    }

    Reduce { state, action in
      switch action {
      case let .loadDataSuccess(entries):
        state.entries = entries
        sortEntries(state: &state)
        return .send(.refreshDisplayTimer)

      case let .createNew(description: description, status: status):
        let newEntityId = uuidGenerator()
        state.entries[id: newEntityId] = createEmptyEntry(
          createdAt: dateGenerator(),
          id: newEntityId,
          status: status,
          description: description
        )
        sortEntries(state: &state)
        return .none

      case .removeAll:
        state.entries.removeAll()
        return .none

      case .startDisplayTimer:
        return .run { send in
          while true {
            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
            await send(.refreshDisplayTimer)
          }
        }
        .cancellable(id: TimerTickID.self, cancelInFlight: true)

      case .stopDisplayTimer:
        return .cancel(id: TimerTickID.self)

      case .refreshDisplayTimer:
        return .concatenate(
          state.entries
            .filter { $0.entry.status == .started }
            .map { .send(.timeTracking(id: $0.id, action: .updateAccumulatedTime)) }
        )

      case .timeTracking(id: _, action: .updateStatus),
           .timeTracking(id: _, action: .toggleStatus):
        sortEntries(state: &state)
        return .none

      case let .timeTracking(id: id, action: .remove):
        state.entries.remove(id: id)
        return .none

      default:
        return .none
      }
    }
  }
}

extension TimeEntryList {
  private func createEmptyEntry(
    createdAt: Date,
    id: UUID,
    status: TrackingEntity.Status,
    description: String?
  ) -> TimeEntry.State {
    let newEntity = TrackingEntity(
      id: id,
      description: .createWith(description: description),
      status: status,
      accumulatedTime: TrackingEntity.AccumulatedTime(
        total: 0,
        accumulatedSession: 0,
        startDate: status == .started ? createdAt : nil
      ),
      createdAt: createdAt,
      updatedAt: createdAt
    )

    return TimeEntry.State(entry: newEntity)
  }

  private func sortEntries(state: inout State) {
    state.entries.sort { first, second in
      switch (first.entry.status, second.entry.status) {
      case (.started, .stopped):
        return true
      case (.stopped, .started):
        return false
      default:
        return first.entry.createdAt > second.entry.createdAt
      }
    }
  }
}
