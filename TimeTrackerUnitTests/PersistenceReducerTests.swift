//
//  PersistenceReducerTests.swift
//  TimeTrackerUnitTests
//
//  Created by Danilo Souza on 10/02/23.
//

import Combine
import ComposableArchitecture
import XCTest
@testable import TimeTracker

@MainActor
final class PersistenceReducerTests: XCTestCase {
  private var currentSavedData: Data?

  func test_load_persistence() async throws {
    let store = TestStore(
      initialState: PersistenceReducer.State(entries: []),
      reducer: PersistenceReducer()
    ) {
      $0.mainQueue = .immediate
    }

    store.dependencies.persistence.load = { self.fakeLoadPersistence() }
    store.dependencies.persistence.save = { self.fakeSavePersistence($0) }

    await store.send(.loadEntries)
    await store.receive(.loadEntriesResponse(getMockEntities()))
    await store.receive(.loadEntriesDidFinish(getMockEntriesIdentifiedArray()))
  }

  func test_save_persistence() async throws {
    let store = TestStore(
      initialState: PersistenceReducer.State(entries: IdentifiedArrayOf(uniqueElements: getMockEntries())),
      reducer: PersistenceReducer()
    ) {
      $0.mainQueue = .immediate
    }
    store.dependencies.persistence.load = { self.fakeLoadPersistence() }
    store.dependencies.persistence.save = { self.fakeSavePersistence($0) }

    await store.send(.saveEntries)

    XCTAssertEqual(currentSavedData, getMockSavedData())
  }
}

// swiftlint:disable all
extension PersistenceReducerTests {
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

  private func getMockEntriesIdentifiedArray() -> IdentifiedArrayOf<TimeEntry.State> {
    IdentifiedArrayOf(uniqueElements: getMockEntries())
  }

  private func fakeLoadPersistence() -> AnyPublisher<[TrackingEntity], Error> {
    Just(getMockEntities()).setFailureType(to: Error.self).eraseToAnyPublisher()
  }

  private func fakeSavePersistence(_ entities: [TrackingEntity]) -> AnyPublisher<Void, Error> {
    currentSavedData = try? JSONEncoder().encode(entities)
    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
  }
}
