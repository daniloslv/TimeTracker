//
//  AppDependencies.swift
//  TimeTracker
//
//  Created by Danilo Souza on 06/02/23.
//

import Combine
import ComposableArchitecture
import Foundation

// MARK: - TrackingPersistenceClient

extension TrackingPersistenceClient: DependencyKey {
    public static let liveValue = Self.liveFileSystemPersistence()
}

public extension TrackingPersistenceClient {
    static func liveFileSystemPersistence() -> Self {
        let persistence = FileSystemPersistence(
            configuration: FileSystemPersistenceConfiguration(),
            fileClient: FileSystemClient()
        )
        return Self(
            load: persistence.loadTrackings,
            save: persistence.saveTrackings(trackings:)
        )
    }
}

extension TrackingPersistenceClient: TestDependencyKey {
    public static let testValue = Self(
        load: { Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() },
        save: { _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    )
}

public extension DependencyValues {
    var persistence: TrackingPersistenceClient {
        get { self[TrackingPersistenceClient.self] }
        set { self[TrackingPersistenceClient.self] = newValue }
    }
}

public struct TimeFormatter: Equatable {
    public var timeStringFrom: (TimeInterval) -> String
    public var dateStringFrom: (Date) -> String

    public static func == (_: TimeFormatter, _: TimeFormatter) -> Bool {
        true
    }
}

// MARK: - TimeFormatter

extension TimeFormatter: DependencyKey {
    public static let liveValue = {
        let componentsFormatter = DateComponentsFormatter()
        componentsFormatter.unitsStyle = .abbreviated
        componentsFormatter.zeroFormattingBehavior = .dropLeading
        componentsFormatter.allowedUnits = [.day, .hour, .minute, .second]

        let dateCreatedFormmater = DateFormatter()
        dateCreatedFormmater.dateStyle = .medium
        dateCreatedFormmater.timeStyle = .short

        return TimeFormatter(
            timeStringFrom: { interval in componentsFormatter.string(from: interval) ?? "" },
            dateStringFrom: { createdAt in dateCreatedFormmater.string(from: createdAt) }
        )
    }()
}

public extension DependencyValues {
    var timeFormatter: TimeFormatter {
        get { self[TimeFormatter.self] }
        set { self[TimeFormatter.self] = newValue }
    }
}
