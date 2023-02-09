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

  public func reduce(
    into state: inout State,
    action: Action
  ) -> ComposableArchitecture.EffectTask<Action> {
    switch action {
    case .toggleStatus:
      let nextStatus: TrackingEntity.Status = state.entry.status == .started ? .stopped : .started
      updateStatus(for: &state, nextStatus: nextStatus, at: dateGenerator())
      return .none

    case let .updateStatus(nextStatus):
      guard state.entry.status != nextStatus
      else { return .none }
      updateStatus(for: &state, nextStatus: nextStatus, at: dateGenerator())
      return .none

    case .updateAccumulatedTime:
      let currentSession = computeAccumulatedTime(for: state.entry, with: dateGenerator())
      state.entry.accumulatedTime.currentSession = currentSession
      state.entry.accumulatedTime.total = state.entry.accumulatedTime.accumulatedSession + currentSession
      return .none

    case let .updateDescription(newDescription):
      guard newDescription != state.entry.description.value
      else { return .none }
      updateDescription(for: &state, nextDescription: newDescription, at: dateGenerator())
      return .none

    case .remove:
      return .none
    }
  }
}

extension TimeEntryReducer {
  private func computeAccumulatedTime(
    for entity: TrackingEntity,
    with date: Date
  ) -> TimeInterval {
    guard entity.status == .started,
          let startDate = entity.accumulatedTime.startDate,
          startDate < date
    else { return entity.accumulatedTime.currentSession }
    return date.timeIntervalSince(startDate)
  }

  private func updateStatus(
    for state: inout State,
    nextStatus: TrackingEntity.Status,
    at currentDate: Date
  ) {
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

    state.entry.status = nextStatus
    state.entry.updatedAt = currentDate
  }

  private func updateDescription(
    for state: inout State,
    nextDescription: String,
    at currentDate: Date
  ) {
    switch nextDescription {
    case let nextDescription where !nextDescription.isEmpty:
      state.entry.description = .description(nextDescription)
      state.entry.updatedAt = currentDate
    default:
      state.entry.description = .description("")
      state.entry.updatedAt = currentDate
    }
  }
}
