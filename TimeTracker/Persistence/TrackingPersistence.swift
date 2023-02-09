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
