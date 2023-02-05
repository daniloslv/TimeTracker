//
//  File.swift
//
//
//  Created by Danilo Souza on 04/02/23.
//

import ComposableArchitecture
import Foundation

public struct TrackingEntity: Equatable {
    public let id: UUID
    public var description: Description
    public var status: Status
    public var accumulatedTime: AccumulatedTime
    public var createdAt: Date
    public var updatedAt: Date
}

public extension TrackingEntity {
    enum Description: Equatable {
        case unnamed
        case description(String)

        public var value: String? {
            switch self {
            case .unnamed: return nil
            case let .description(text): return text
            }
        }

        public static func create(description: String?) -> Description {
            switch description {
            case let name? where !name.isEmpty:
                return .description(name)
            default:
                return .unnamed
            }
        }
    }

    enum Status: Equatable {
        case started
        case stopped
    }

    struct AccumulatedTime: Equatable {
        public var total: TimeInterval = 0
        public var startDate: Date?
    }
}

public struct TimeEntryReducer: ReducerProtocol {
    @Dependency(\.date) var dateGenerator

    public struct State: Equatable {
        var entry: TrackingEntity
    }

    public enum Action: Equatable {
        case updateStatus(TrackingEntity.Status)
        case updateAccumulatedTime
        case updateDescription(String?)
    }

    public func reduce(
        into state: inout State,
        action: Action
    ) -> ComposableArchitecture.EffectTask<Action> {
        switch action {
        case let .updateStatus(status):
            guard state.entry.status != status
            else { return .none }
            let currentDate = dateGenerator()
            state.entry.accumulatedTime.total = computeAccumulatedTime(for: state.entry, with: currentDate)
            state.entry.accumulatedTime.startDate = status == .started
                ? currentDate
                : nil
            state.entry.status = status
            state.entry.updatedAt = currentDate
            return .none

        case .updateAccumulatedTime:
            let currentDate = dateGenerator()
            state.entry.accumulatedTime.total = computeAccumulatedTime(for: state.entry, with: currentDate)
            state.entry.updatedAt = currentDate
            return .none

        case let .updateDescription(name):
            guard name != state.entry.description.value
            else { return .none }
            let currentDate = dateGenerator()
            switch name {
            case let name? where !name.isEmpty:
                state.entry.description = .description(name)
                state.entry.updatedAt = currentDate
            default:
                state.entry.description = .unnamed
                state.entry.updatedAt = currentDate
            }
            return .none
        }
    }

    private func computeAccumulatedTime(
        for entity: TrackingEntity,
        with date: Date
    ) -> TimeInterval {
        guard entity.status == .started,
              let startDate = entity.accumulatedTime.startDate,
              startDate < date
        else { return entity.accumulatedTime.total }
        return entity.accumulatedTime.total + date.timeIntervalSince(startDate)
    }
}
