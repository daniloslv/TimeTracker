//
//  TimeEntryCollectionReducer.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import ComposableArchitecture
import Foundation

public struct TimeEntryCollectionReducer: ReducerProtocol {
    @Dependency(\.uuid) var uuidGenerator
    @Dependency(\.date) var dateGenerator

    public struct State: Equatable {
        public var entries: IdentifiedArrayOf<TimeEntryReducer.State> = []
    }

    public enum Action: Equatable {
        case createNew(description: String?, status: TrackingEntity.Status)
        case insert(entry: TimeEntryReducer.State)
        case remove(id: UUID)
        case startDisplayTimer
        case updateEntries
        case loadEntries
        case saveEntries
        case timeTracking(id: TimeEntryReducer.State.ID, action: TimeEntryReducer.Action)
    }

    private enum TimerTickID {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .createNew(description: description, status: status):
                let createdAt = dateGenerator()
                let newEntityId = uuidGenerator()
                guard state.entries[id: newEntityId] == nil
                else { return .none }
                let newEntity = TrackingEntity(
                    id: newEntityId,
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
                state.entries[id: newEntityId] = TimeEntryReducer.State(entry: newEntity)
                return .none

            case let .insert(entry: entry):
                guard state.entries[id: entry.id] == nil
                else { return .none }
                state.entries[id: entry.id] = entry
                return .none

            case let .remove(id: id):
                guard state.entries[id: id] != nil
                else { return .none }
                state.entries[id: id] = nil
                return .none

            case .timeTracking(id: _, action: _):
                return .none

            case .startDisplayTimer:
                return .run { send in
                    while true {
                        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
                        await send(.updateEntries)
                    }
                }
                .cancellable(id: TimerTickID.self, cancelInFlight: true)

            case .updateEntries:
                return .merge(
                    state.entries.map {
                        .send(.timeTracking(id: $0.id, action: .updateAccumulatedTime))
                    }
                )

            case .loadEntries:
                fatalError()
            case .saveEntries:
                fatalError()
            }
        }
        .forEach(\.entries, action: /Action.timeTracking(id:action:)) {
            TimeEntryReducer()
        }
    }
}
