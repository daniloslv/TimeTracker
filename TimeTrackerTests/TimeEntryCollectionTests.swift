//
//  TimeEntryCollectionTests.swift
//  TimeTrackerTests
//
//  Created by Danilo Souza on 05/02/23.
//

import ComposableArchitecture
@testable import TimeTracker
import XCTest

@MainActor
final class TimeEntryCollectionTests: XCTestCase {
    func test_create_new_entry() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let newTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .unnamed,
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [:]),
            reducer: TimeEntryCollectionReducer()
        )

        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.createNew(description: nil)) {
            $0.entries = [newTimeTracking.id: newTimeTracking]
        }
    }

    func test_create_new_entry_with_description() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let newTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("My important project"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [:]),
            reducer: TimeEntryCollectionReducer()
        )

        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.createNew(description: "My important project")) {
            $0.entries = [newTimeTracking.id: newTimeTracking]
        }
    }

    func test_insert_entry() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let newTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("My important project"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [:]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.insert(entity: newTimeTracking)) {
            $0.entries = [newTimeTracking.id: newTimeTracking]
        }
    }

    func test_insert_entry_already_existing() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let existingTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("My important project"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let equalTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("My important project"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let sameIdTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("This has a different project name"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [existingTimeTracking.id: existingTimeTracking]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.insert(entity: equalTimeTracking))
        await store.send(.insert(entity: sameIdTimeTracking))
    }

    func test_remove_entry() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let existingTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("My important project"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [existingTimeTracking.id: existingTimeTracking]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.remove(id: existingTimeTracking.id)) {
            $0.entries = [:]
        }
    }

    func test_remove_entry_non_existing() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let existingTimeTracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            description: .description("My important project"),
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [existingTimeTracking.id: existingTimeTracking]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.remove(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!))
    }

    func test_remove_entry_on_empty_collection() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [:]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.remove(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!))
    }
}
