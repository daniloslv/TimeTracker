//
//  File.swift
//
//
//  Created by Danilo Souza on 04/02/23.
//

import ComposableArchitecture
import Foundation

public struct TimeEntryReducer: ReducerProtocol {
    @Dependency(\.date) var dateGenerator

    public struct State: Equatable, Identifiable {
        public var id: UUID { entry.id }
        public var entry: TrackingEntity

        public init(entry: TrackingEntity) {
            self.entry = entry
        }
    }

    public enum Action: Equatable {
        case toggleStatus
        case updateStatus(TrackingEntity.Status)
        case updateDescription(String)
        case updateAccumulatedTime
        case remove
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleStatus:
                switch state.entry.status {
                case .started: return .send(.updateStatus(.stopped))
                case .stopped: return .send(.updateStatus(.started))
                }

            case let .updateStatus(nextStatus):
                guard state.entry.status != nextStatus
                else { return .none }
                let currentDate = dateGenerator()
                defer {
                    state.entry.status = nextStatus
                    state.entry.updatedAt = currentDate
                }
                switch nextStatus {
                case .started:
                    state.entry.accumulatedTime.total = state.entry.accumulatedTime.accumulatedSession
                    state.entry.accumulatedTime.currentSession = 0
                    state.entry.accumulatedTime.startDate = currentDate
                case .stopped:
                    state.entry.accumulatedTime.currentSession = computeAccumulatedTime(for: state.entry, with: currentDate)
                    state.entry.accumulatedTime.accumulatedSession += state.entry.accumulatedTime.currentSession
                    state.entry.accumulatedTime.total = state.entry.accumulatedTime.accumulatedSession
                    state.entry.accumulatedTime.currentSession = 0
                    state.entry.accumulatedTime.startDate = nil
                }
                return .none

            case .updateAccumulatedTime:
                let currentDate = dateGenerator()
                state.entry.accumulatedTime.currentSession = computeAccumulatedTime(for: state.entry, with: currentDate)
                state.entry.accumulatedTime.total = state.entry.accumulatedTime.accumulatedSession + state.entry.accumulatedTime.currentSession
                return .none

            case let .updateDescription(name):
                guard name != state.entry.description.value
                else { return .none }
                let currentDate = dateGenerator()
                switch name {
                case let name where !name.isEmpty:
                    state.entry.description = .description(name)
                    state.entry.updatedAt = currentDate
                default:
                    state.entry.description = .description("")
                    state.entry.updatedAt = currentDate
                }
                return .none

            case .remove:
                return .none
            }
        }
        .analytics(
            isEnabled: { state, action in
                switch action {
                case Action.updateDescription,
                     Action.remove,
                     Action.updateStatus:
                    return true
                default: return false
                }
            },
            triggerOnChageOf: \.entry
        )
    }
}

extension TrackingEntity: AnalyticsEventProducer {
    public func produceAnalyticsEvent() -> String {
        return [
            "Entity id: \(self.id)",
            "description: \(self.description.value ?? "")",
            "status: \(self.status)",
        ].joined(separator: "\n")
        
    }
}

private extension TimeEntryReducer {
    func computeAccumulatedTime(
        for entity: TrackingEntity,
        with date: Date
    ) -> TimeInterval {
        guard entity.status == .started,
              let startDate = entity.accumulatedTime.startDate,
              startDate < date
        else { return entity.accumulatedTime.currentSession }
        return date.timeIntervalSince(startDate)
    }
}
