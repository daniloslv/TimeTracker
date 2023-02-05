//
//  TrackingEntity.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

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

        public static func createWith(description: String?) -> Description {
            switch description {
            case let name? where !name.isEmpty:
                return .description(name)
            default:
                return .unnamed
            }
        }
    }
}

public extension TrackingEntity {
    enum Status: Equatable {
        case started
        case stopped
    }
}

public extension TrackingEntity {
    struct AccumulatedTime: Equatable {
        public var total: TimeInterval = 0
        public var accumulatedSession: TimeInterval = 0
        public var currentSession: TimeInterval = 0
        public var startDate: Date?
    }
}
