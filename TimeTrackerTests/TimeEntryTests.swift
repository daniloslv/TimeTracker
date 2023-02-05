//
//  TimeEntryTests.swift
//
//
//  Created by Danilo Souza on 04/02/23.
//

import ComposableArchitecture
@testable import TimeTracker
import XCTest

@MainActor
final class TimeEntryTests: XCTestCase {
    func test_update_status_start_then_stop() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let startDate = Date(timeIntervalSince1970: 1_111_111_000)
        let updateDate = Date(timeIntervalSince1970: 1_111_111_100)

        let timeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryReducer.State(entry: timeTracking),
            reducer: TimeEntryReducer()
        )

        store.dependencies.date = DateGenerator { startDate }
        await store.send(.updateStatus(.started)) {
            $0.entry.status = .started
            $0.entry.accumulatedTime.startDate = startDate
            $0.entry.updatedAt = startDate
        }

        store.dependencies.date = DateGenerator { updateDate }
        await store.send(.updateStatus(.stopped)) {
            $0.entry.status = .stopped
            $0.entry.accumulatedTime.startDate = nil
            $0.entry.accumulatedTime.total = 100
            $0.entry.updatedAt = updateDate
        }
    }

    func test_update_status_stop_then_start() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let startDate = Date(timeIntervalSince1970: 1_111_111_000)
        let updateDate = Date(timeIntervalSince1970: 1_111_111_100)

        let timeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .started,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryReducer.State(entry: timeTracking),
            reducer: TimeEntryReducer()
        )

        store.dependencies.date = DateGenerator { startDate }
        await store.send(.updateStatus(.stopped)) {
            $0.entry.status = .stopped
            $0.entry.updatedAt = startDate
        }

        store.dependencies.date = DateGenerator { updateDate }
        await store.send(.updateStatus(.started)) {
            $0.entry.status = .started
            $0.entry.accumulatedTime.total = 0
            $0.entry.accumulatedTime.startDate = updateDate
            $0.entry.updatedAt = updateDate
        }
    }

    func test_update_stopped_status_to_same_status() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let startDate = Date(timeIntervalSince1970: 1_111_111_000)
        let updateDate = Date(timeIntervalSince1970: 1_111_111_100)

        let pausedTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryReducer.State(entry: pausedTimeTracking),
            reducer: TimeEntryReducer()
        )

        store.dependencies.date = DateGenerator { startDate }
        await store.send(.updateStatus(.stopped))

        store.dependencies.date = DateGenerator { updateDate }
        await store.send(.updateStatus(.stopped))
    }

    func test_update_started_status_to_same_status() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let startDate = Date(timeIntervalSince1970: 1_111_111_000)
        let updateDate = Date(timeIntervalSince1970: 1_111_111_100)

        let runningTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .started,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryReducer.State(entry: runningTimeTracking),
            reducer: TimeEntryReducer()
        )

        store.dependencies.date = DateGenerator { startDate }
        await store.send(.updateStatus(.started))

        store.dependencies.date = DateGenerator { updateDate }
        await store.send(.updateStatus(.started))
    }

    func test_update_started_status_with_past_date() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let startDate = Date(timeIntervalSince1970: 1_111_111_000)
        // The update date is before start date.
        let updateDate = Date(timeIntervalSince1970: 1_111_110_100)

        let runningTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .started,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryReducer.State(entry: runningTimeTracking),
            reducer: TimeEntryReducer()
        )

        store.dependencies.date = DateGenerator { startDate }
        await store.send(.updateStatus(.started))

        store.dependencies.date = DateGenerator { updateDate }
        await store.send(.updateStatus(.started))
    }

    func test_update_name() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let firstUpdateDate = Date(timeIntervalSince1970: 1_111_110_000)
        let secondUpdateDate = Date(timeIntervalSince1970: 1_111_120_000)
        let thirdUpdateDate = Date(timeIntervalSince1970: 1_111_130_000)
        let fourthUpdateDate = Date(timeIntervalSince1970: 1_111_140_000)

        let timeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .started,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryReducer.State(entry: timeTracking),
            reducer: TimeEntryReducer()
        )

        // Should update the name.
        store.dependencies.date = DateGenerator { firstUpdateDate }
        await store.send(.updateDescription("My work task")) {
            $0.entry.description = .description("My work task")
            $0.entry.updatedAt = firstUpdateDate
        }
        // Should result in .unnamed.
        store.dependencies.date = DateGenerator { secondUpdateDate }
        await store.send(.updateDescription("")) {
            $0.entry.description = .unnamed
            $0.entry.updatedAt = secondUpdateDate
        }
        // Should change the name.
        store.dependencies.date = DateGenerator { thirdUpdateDate }
        await store.send(.updateDescription("My important project")) {
            $0.entry.description = .description("My important project")
            $0.entry.updatedAt = thirdUpdateDate
        }
        // Should result in .unnamed.
        store.dependencies.date = DateGenerator { fourthUpdateDate }
        await store.send(.updateDescription(nil)) {
            $0.entry.description = .unnamed
            $0.entry.updatedAt = fourthUpdateDate
        }
    }
}
