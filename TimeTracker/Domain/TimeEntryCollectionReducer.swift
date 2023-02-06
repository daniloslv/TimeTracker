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
        case insert(entry: TimeEntryReducer.State)
        case remove(id: UUID)
        case startDisplayTimer
        case updateEntries
        case loadEntries
        case updateLoadedEntries([TrackingEntity])
        case saveEntries
        case timeTracking(id: TimeEntryReducer.State.ID, action: TimeEntryReducer.Action)
        case nothing
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
                return .send(.saveEntries)

            case let .insert(entry: entry):
                guard state.entries[id: entry.id] == nil
                else { return .none }
                state.entries[id: entry.id] = entry
                return .send(.saveEntries)

            case let .remove(id: id):
                guard state.entries[id: id] != nil
                else { return .none }
                state.entries[id: id] = nil
                return .send(.saveEntries)

            case .timeTracking(id: _, action: .toggleStatus),
                 .timeTracking(id: _, action: .updateStatus),
                 .timeTracking(id: _, action: .updateDescription):
                return .send(.saveEntries)

            case .timeTracking:
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
                return EffectPublisher(
                    persistence.loadTrackings()
                        .receive(on: mainQueue)
                        .replaceError(with: [])
                        .map(Action.updateLoadedEntries)
                )

            case let .updateLoadedEntries(loadedEntries):
                let sortedTrackings = loadedEntries
                    .sorted { $0.createdAt < $1.createdAt }
                    .map(TimeEntryReducer.State.init(entry:))
                state.entries = IdentifiedArrayOf(uniqueElements: sortedTrackings)
                return .send(.updateEntries)

            case .saveEntries:
                return EffectPublisher(
                    persistence.saveTrackings(trackings: state.entries.map(\.entry))
                        .replaceError(with: ())
                        .map { _ in Action.nothing }
                )

            case .nothing:
                return .none
            }
        }
        .forEach(\.entries, action: /Action.timeTracking(id:action:)) {
            TimeEntryReducer()
        }
    }
}
