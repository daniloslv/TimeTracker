//
//  TrackingPersistenceProtocol.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import Dependencies
import Foundation

public protocol TrackingPersistenceProtocol {
    func loadTrackings() -> AnyPublisher<[TrackingEntity], Error>
    func saveTrackings(trackings: [TrackingEntity]) -> AnyPublisher<Void, Error>
}

public struct TrackingPersistenceClient: TrackingPersistenceProtocol {
    public var load: () -> AnyPublisher<[TrackingEntity], Error>
    public var save: ([TrackingEntity]) -> AnyPublisher<Void, Error>

    public func loadTrackings() -> AnyPublisher<[TrackingEntity], Error> {
        load()
    }

    public func saveTrackings(trackings: [TrackingEntity]) -> AnyPublisher<Void, Error> {
        save(trackings)
    }
}

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
