//
//  AppReducerTests.swift
//  TimeTrackerUnitTests
//
//  Created by Danilo Souza on 13/02/23.
//

import Combine
import ComposableArchitecture
import XCTest
@testable import TimeTracker

@MainActor
final class AppReducerTests: XCTestCase {
  var createdAt: Date!
  var id: UUID!

  override func setUp() async throws {
    createdAt = Date(timeIntervalSince1970: 1_111_100_000)
    id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
  }

  typealias ActionAssert = (
    action: AppReducer.Action,
    state: AppReducer.State,
    assert: ((inout AppReducer.State) throws -> Void)?
  )
  func test_all_actions_trigger_save_entries_action() async throws {
    let createdAt = createdAt!
    let id = id!
    let existingTimeTracking = TrackingEntity(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      description: .description("My important project"),
      status: .stopped,
      accumulatedTime: TrackingEntity.AccumulatedTime(),
      createdAt: createdAt,
      updatedAt: createdAt
    )
    let emptyListState = TimeEntryList.State(entries: [])
    let listState = TimeEntryList.State(entries: [TimeEntry.State(entry: existingTimeTracking)])

    let persistenceAssertActions: [ActionAssert] = [
      (
        action: .listAction(.createNew(description: "Test tracking", status: .started)),
        state: AppReducer.State(timeEntryList: emptyListState),
        assert: {
          $0.timeEntryList = listState
          $0.timeEntryList.entries[id: id]?.entry.status = .started
          $0.timeEntryList.entries[id: id]?.entry.description = .description("Test tracking")
          $0.timeEntryList.entries[id: id]?.entry.createdAt = createdAt
          $0.timeEntryList.entries[id: id]?.entry.updatedAt = createdAt
          $0.timeEntryList.entries[id: id]?.entry.accumulatedTime.startDate = createdAt
        }
      ),

      (
        action: .listAction(.createNew(description: "Test tracking", status: .stopped)),
        state: AppReducer.State(timeEntryList: emptyListState),
        assert: {
          $0.timeEntryList = listState
          $0.timeEntryList.entries[id: id]?.entry.status = .stopped
          $0.timeEntryList.entries[id: id]?.entry.description = .description("Test tracking")
          $0.timeEntryList.entries[id: id]?.entry.createdAt = createdAt
          $0.timeEntryList.entries[id: id]?.entry.updatedAt = createdAt
        }
      ),

      (
        action: .listAction(.removeAll),
        state: AppReducer.State(timeEntryList: listState),
        assert: {
          $0.timeEntryList = emptyListState
        }
      ),

      (
        action: .listAction(.timeTracking(id: id, action: .remove)),
        state: AppReducer.State(timeEntryList: listState),
        assert: {
          $0.timeEntryList = emptyListState
        }
      ),

      (
        action: .listAction(.timeTracking(id: id, action: .updateDescription("Test Description"))),
        state: AppReducer.State(timeEntryList: listState),
        assert: {
          $0.timeEntryList.entries[id: id]?.entry.description = .description("Test Description")
          $0.timeEntryList.entries[id: id]?.entry.updatedAt = createdAt
        }
      ),

      (
        action: .listAction(.timeTracking(id: id, action: .updateStatus(.started))),
        state: AppReducer.State(timeEntryList: listState),
        assert: {
          $0.timeEntryList.entries[id: id]?.entry.status = .started
          $0.timeEntryList.entries[id: id]?.entry.accumulatedTime.startDate = createdAt
          $0.timeEntryList.entries[id: id]?.entry.updatedAt = createdAt
        }
      ),

      (
        action: .listAction(.timeTracking(id: id, action: .updateStatus(.stopped))),
        state: AppReducer.State(timeEntryList: listState),
        assert: nil
      ),

      (
        action: .listAction(.timeTracking(id: id, action: .toggleStatus)),
        state: AppReducer.State(timeEntryList: listState),
        assert: {
          $0.timeEntryList.entries[id: id]?.entry.status = .started
          $0.timeEntryList.entries[id: id]?.entry.accumulatedTime.startDate = createdAt
          $0.timeEntryList.entries[id: id]?.entry.updatedAt = createdAt
        }
      ),
    ]

    for assertAction in persistenceAssertActions {
      try await assert_action_triggers_save_entries(assertAction: assertAction)
    }
  }

  private func assert_action_triggers_save_entries(
    assertAction: ActionAssert,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws {
    let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
    let store = TestStore(
      initialState: assertAction.state,
      reducer: AppReducer()
    ) {
      $0.mainQueue = .immediate
      $0.date = .constant(createdAt)
      $0.uuid = .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    }

    await store.send(
      assertAction.action,
      assert: assertAction.assert,
      file: file,
      line: line
    )
    await store.receive(.persistenceAction(.saveEntries), file: file, line: line)
  }
}
