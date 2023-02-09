//
//  TimeEntryCollectionReducer.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import ComposableArchitecture
import Foundation

public struct TimeEntryCollectionReducer: ReducerProtocol {
  @Dependency(\.uuid) var uuidGenerator
  @Dependency(\.date) var dateGenerator
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.persistence) var persistence

  private var cancellables: Set<AnyCancellable> = []

  public struct State: Equatable {
    public var entries: IdentifiedArrayOf<TimeEntryReducer.State> = []
  }

  public enum Action: Equatable {
    case createNew(description: String?, status: TrackingEntity.Status)
    case remove(id: UUID)
    case removeAll
    case startDisplayTimer
    case stopDisplayTimer
    case refreshDisplayTimer
    case timeTracking(id: TimeEntryReducer.State.ID, action: TimeEntryReducer.Action)
    case trackingReducer(TimeEntryReducer.Action)

    case sortEntries
    case loadEntries
    case loadEntriesResponse([TrackingEntity])
    case saveEntries
    case noOp
  }

  private enum TimerTickID {}
  private enum CommitUpdateDescriptionID {}

  public var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .createNew(description: description, status: status):
        let newEntityId = uuidGenerator()
        state.entries[id: newEntityId] = createEmptyEntry(
          createdAt: dateGenerator(),
          id: newEntityId,
          status: status,
          description: description
        )
        return .concatenate(
          .send(.sortEntries),
          .send(.saveEntries)
        )

      case let .remove(id: id):
        guard state.entries[id: id] != nil
        else { return .none }
        state.entries[id: id] = nil
        return .send(.saveEntries)

      case .removeAll:
        state.entries = []
        return .send(.saveEntries)

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

      case .sortEntries:
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
        return .none

      case .refreshDisplayTimer:
        return .concatenate(
          state.entries
            .filter { $0.entry.status == .started }
            .map { .send(.timeTracking(id: $0.id, action: .updateAccumulatedTime)) }
        )

      case .timeTracking(id: _, action: .updateStatus),
           // TODO: need to add a test for trigging a .save after toggleStatus.
           .timeTracking(id: _, action: .toggleStatus):
        return .concatenate(
          .send(.sortEntries),
          .send(.saveEntries)
        )

      case let .timeTracking(id: id, action: action):
        guard state.entries[id: id] != nil
        else { return .none }
        switch action {
        case .remove:
          return .send(.remove(id: id))
        case .updateDescription:
          return .run { send in
            try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
            await send(.saveEntries)
          }
          .cancellable(id: CommitUpdateDescriptionID.self, cancelInFlight: true)
        default:
          return .none
        }

      case .trackingReducer:
        return .none

      case .loadEntries:
        return EffectPublisher(
          persistence.loadTrackings()
            .replaceError(with: [])
            .map(Action.loadEntriesResponse)
        )

      case let .loadEntriesResponse(loadedEntries):
        let sortedTrackings = loadedEntries
          .map(TimeEntryReducer.State.init(entry:))
        state.entries = IdentifiedArrayOf(uniqueElements: sortedTrackings)
        return .concatenate(
          .send(.sortEntries),
          .send(.refreshDisplayTimer)
        )

      case .saveEntries:
        return EffectPublisher(
          persistence.saveTrackings(trackings: state.entries.map(\.entry))
            .replaceError(with: ())
            .map { _ in print("Saved entries...", action) }
            .map { _ in Action.noOp }
        )

      case .noOp:
        return .none
      }
    }
    .forEach(\.entries, action: /Action.timeTracking(id:action:)) {
      TimeEntryReducer()
    }
  }
}

extension TimeEntryCollectionReducer {
  private func createEmptyEntry(
    createdAt: Date,
    id: UUID,
    status: TrackingEntity.Status,
    description: String?
  ) -> TimeEntryReducer.State {
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

    return TimeEntryReducer.State(entry: newEntity)
  }
}
