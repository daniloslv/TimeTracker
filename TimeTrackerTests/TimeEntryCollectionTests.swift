//
//  TimeEntryCollectionTests.swift
//  TimeTrackerTests
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import ComposableArchitecture
@testable import TimeTracker
import XCTest

@MainActor
final class TimeEntryCollectionTests: XCTestCase {
    private var currentSavedData: Data?

    override func setUpWithError() throws {
        currentSavedData = nil
    }

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
            initialState: TimeEntryCollectionReducer.State(entries: []),
            reducer: TimeEntryCollectionReducer()
        )

        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.createNew(description: nil, status: .stopped)) {
            $0.entries = [TimeEntryReducer.State(entry: newTimeTracking)]
        }
        await store.receive(.saveEntries)
        await store.receive(.nothing)
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
            initialState: TimeEntryCollectionReducer.State(entries: []),
            reducer: TimeEntryCollectionReducer()
        )

        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.createNew(description: "My important project", status: .stopped)) {
            $0.entries = [TimeEntryReducer.State(entry: newTimeTracking)]
        }
        await store.receive(.saveEntries)
        await store.receive(.nothing)
    }

    func test_insert_entry() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let newTimeTrackingEntry: TimeEntryReducer.State = .init(
            entry: TrackingEntity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                description: .description("My important project"),
                status: .stopped,
                accumulatedTime: TrackingEntity.AccumulatedTime(),
                createdAt: createdAt,
                updatedAt: createdAt
            )
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: []),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.insert(entry: newTimeTrackingEntry)) {
            $0.entries = [newTimeTrackingEntry]
        }
        await store.receive(.saveEntries)
        await store.receive(.nothing)
    }

    func test_insert_entry_already_existing() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let existingTimeTrackingEntry: TimeEntryReducer.State = .init(
            entry: TrackingEntity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                description: .description("My important project"),
                status: .stopped,
                accumulatedTime: TrackingEntity.AccumulatedTime(),
                createdAt: createdAt,
                updatedAt: createdAt
            )
        )

        let equalTimeTrackingEntry: TimeEntryReducer.State = .init(
            entry: TrackingEntity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                description: .description("My important project"),
                status: .stopped,
                accumulatedTime: TrackingEntity.AccumulatedTime(),
                createdAt: createdAt,
                updatedAt: createdAt
            )
        )

        let sameIdTimeTrackingEntry: TimeEntryReducer.State = .init(
            entry: TrackingEntity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                description: .description("This has a different project name"),
                status: .stopped,
                accumulatedTime: TrackingEntity.AccumulatedTime(),
                createdAt: createdAt,
                updatedAt: createdAt
            )
        )

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: [existingTimeTrackingEntry]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.insert(entry: equalTimeTrackingEntry))
        await store.send(.insert(entry: sameIdTimeTrackingEntry))
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
            initialState: TimeEntryCollectionReducer.State(entries: [TimeEntryReducer.State(entry: existingTimeTracking)]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.remove(id: existingTimeTracking.id)) {
            $0.entries = []
        }
        await store.receive(.saveEntries)
        await store.receive(.nothing)
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
            initialState: TimeEntryCollectionReducer.State(entries: [TimeEntryReducer.State(entry: existingTimeTracking)]),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.remove(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!))
    }

    func test_remove_entry_on_empty_collection() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: []),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)

        await store.send(.remove(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!))
    }

    func test_load_persistence() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: []),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)
        store.dependencies.mainQueue = .immediate
        store.dependencies.persistence.load = { self.fakeLoadPersistence() }
        store.dependencies.persistence.save = { self.fakeSavePersistence($0) }

        await store.send(.loadEntries)
        await store.receive(.updateLoadedEntries(getMockEntities())) {
            $0.entries = IdentifiedArrayOf(uniqueElements: self.getMockEntries())
        }
        await store.receive(.updateEntries)
        await store.receive(.timeTracking(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, action: .updateAccumulatedTime))
        await store.receive(.timeTracking(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, action: .updateAccumulatedTime))
        await store.receive(.timeTracking(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, action: .updateAccumulatedTime))
        await store.receive(.timeTracking(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, action: .updateAccumulatedTime))
    }

    func test_save_persistence() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let store = TestStore(
            initialState: TimeEntryCollectionReducer.State(entries: IdentifiedArrayOf(uniqueElements: getMockEntries())),
            reducer: TimeEntryCollectionReducer()
        )
        store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        store.dependencies.date = .constant(createdAt)
        store.dependencies.mainQueue = .immediate
        store.dependencies.persistence.load = { self.fakeLoadPersistence() }
        store.dependencies.persistence.save = { self.fakeSavePersistence($0) }

        await store.send(.saveEntries)
        await store.receive(.nothing)
        XCTAssertEqual(currentSavedData, getMockSavedData())
    }
}

extension TimeEntryCollectionTests {
    private func getMockSavedData() -> Data? {
        """
        [{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000001","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"unnamed":{}},"createdAt":132792800},{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000002","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"description":{"_0":"My Project"}},"createdAt":132792800},{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000003","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"unnamed":{}},"createdAt":132792800},{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000004","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"description":{"_0":"My Task"}},"createdAt":132792800}]
        """.data(using: .utf8)
    }

    private func getMockEntities() -> [TrackingEntity] {
        let json = getMockSavedData()!
        return try! JSONDecoder().decode([TrackingEntity].self, from: json)
    }

    private func getMockEntries() -> [TimeEntryReducer.State] {
        getMockEntities().map(TimeEntryReducer.State.init(entry:))
    }

    private func fakeLoadPersistence() -> AnyPublisher<[TrackingEntity], Error> {
        Just(getMockEntities()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    private func fakeSavePersistence(_ entities: [TrackingEntity]) -> AnyPublisher<Void, Error> {
        currentSavedData = try? JSONEncoder().encode(entities)
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
