//
//  TimeEntryListTests.swift
//  TimeTrackerTests
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import ComposableArchitecture
import XCTest
@testable import TimeTracker

@MainActor
final class TimeEntryListTests: XCTestCase {
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
      initialState: TimeEntryList.State(entries: []),
      reducer: TimeEntryList()
    )

    store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    store.dependencies.date = .constant(createdAt)
    store.dependencies.mainQueue = .immediate

    await store.send(.createNew(description: nil, status: .stopped)) {
      $0.entries = [TimeEntry.State(entry: newTimeTracking)]
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
      initialState: TimeEntryList.State(entries: []),
      reducer: TimeEntryList()
    ) {
      $0.mainQueue = .immediate
    }

    store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    store.dependencies.date = .constant(createdAt)

    await store.send(.createNew(description: "My important project", status: .stopped)) {
      $0.entries = [TimeEntry.State(entry: newTimeTracking)]
    }
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
      initialState: TimeEntryList.State(entries: [TimeEntry.State(entry: existingTimeTracking)]),
      reducer: TimeEntryList()
    )
    store.dependencies.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    store.dependencies.date = .constant(createdAt)
    store.dependencies.mainQueue = .immediate

    await store.send(.timeTracking(id: existingTimeTracking.id, action: .remove)) {
      $0.entries = []
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
      initialState: TimeEntryList.State(entries: [TimeEntry.State(entry: existingTimeTracking)]),
      reducer: TimeEntryList()
    ) {
      $0.mainQueue = .immediate
    }

    let nonExistingId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    await store.send(.timeTracking(id: nonExistingId, action: .remove))
  }

  func test_remove_entry_on_empty_collection() async throws {
    let store = TestStore(
      initialState: TimeEntryList.State(entries: []),
      reducer: TimeEntryList()
    )
    store.dependencies.mainQueue = .immediate

    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    await store.send(.timeTracking(id: id, action: .remove))
  }
}

// swiftlint:disable all
extension TimeEntryListTests {
  private func getMockSavedData() -> Data? {
    """
    [{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000001","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"unnamed":{}},"createdAt":132792800},{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000002","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"description":{"_0":"My Project"}},"createdAt":132792800},{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000003","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"unnamed":{}},"createdAt":132792800},{"status":{"started":{}},"id":"00000000-0000-0000-0000-000000000004","accumulatedTime":{"currentSession":0,"accumulatedSession":0,"startDate":132792800,"total":0},"updatedAt":132792800,"description":{"description":{"_0":"My Task"}},"createdAt":132792800}]
    """.data(using: .utf8)
  }

  private func getMockEntities() -> [TrackingEntity] {
    let json = getMockSavedData()!
    return try! JSONDecoder().decode([TrackingEntity].self, from: json)
  }

  private func getMockEntries() -> [TimeEntry.State] {
    getMockEntities().map(TimeEntry.State.init(entry:))
  }

  private func fakeLoadPersistence() -> AnyPublisher<[TrackingEntity], Error> {
    Just(getMockEntities()).setFailureType(to: Error.self).eraseToAnyPublisher()
  }

  private func fakeSavePersistence(_ entities: [TrackingEntity]) -> AnyPublisher<Void, Error> {
    currentSavedData = try? JSONEncoder().encode(entities)
    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
  }
}
