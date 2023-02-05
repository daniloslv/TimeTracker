//
//  TimeEntryCollectionReducer.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import ComposableArchitecture
import Foundation

public struct TrackingEntityCollection: Equatable {
    public let id: UUID
    public var createdAt: Date
    public var updatedAt: Date
}

public struct TimeEntryCollectionReducer: ReducerProtocol {
    @Dependency(\.uuid) var uuidGenerator
    @Dependency(\.date) var dateGenerator

    public struct State: Equatable {
        var entries: [UUID: TrackingEntity]
    }

    public enum Action: Equatable {
        case createNew(description: String?)
        case insert(entity: TrackingEntity)
        case remove(id: UUID)
        case loadEntries
        case saveEntries
    }

    public func reduce(
        into state: inout State,
        action: Action
    ) -> ComposableArchitecture.EffectTask<Action> {
        switch action {
        case let .createNew(description: description):
            let createdAt = dateGenerator()
            let newEntityId = uuidGenerator()
            guard state.entries[newEntityId] == nil
            else { return .none }
            let newEntity = TrackingEntity(
                id: newEntityId,
                description: .create(description: description),
                status: .stopped,
                accumulatedTime: TrackingEntity.AccumulatedTime(),
                createdAt: createdAt,
                updatedAt: createdAt
            )
            state.entries[newEntityId] = newEntity
            return .none

        case let .insert(entity: entity):
            guard state.entries[entity.id] == nil
            else { return .none }
            state.entries[entity.id] = entity
            return .none

        case let .remove(id: id):
            guard state.entries[id] != nil
            else { return .none }
            state.entries[id] = nil
            return .none

        case .loadEntries:
            fatalError()
        case .saveEntries:
            fatalError()
        }
    }
}
