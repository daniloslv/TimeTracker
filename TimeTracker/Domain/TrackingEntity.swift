//
//  TrackingEntity.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import Foundation

public struct TrackingEntity: Equatable, Codable {
  public let id: UUID
  public var description: Description
  public var status: Status
  public var accumulatedTime: AccumulatedTime
  public var createdAt: Date
  public var updatedAt: Date
}

extension TrackingEntity {
  public enum Description: Equatable, Codable {
    case unnamed
    case description(String)

    public var value: String? {
      switch self {
      case .unnamed:
        return nil
      case let .description(text):
        return text
      }
    }

    public static func createWith(description: String?) -> Description {
      switch description {
      case let name?:
        return .description(name)
      default:
        return .unnamed
      }
    }
  }
}

extension TrackingEntity {
  public enum Status: Equatable, Codable {
    case started
    case stopped
  }
}

extension TrackingEntity {
  public struct AccumulatedTime: Equatable, Codable {
    public var total: TimeInterval = 0
    public var accumulatedSession: TimeInterval = 0
    public var currentSession: TimeInterval = 0
    public var startDate: Date?
  }
}
