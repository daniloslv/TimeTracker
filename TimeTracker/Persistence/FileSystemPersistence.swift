//
//  FileSystemPersistence.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import Foundation

public enum FileSystemPersistenceError: Error {
  case invalidFilePath(URL?)
  case decodingError(Error)
  case encodingError(Error)
  case fileSavingError(Error)
}

public struct FileSystemPersistenceConfiguration {
  public var trackingsPath: URL? {
    let documentDirectory = try? FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    return documentDirectory?.appendingPathComponent(fileName)
  }

  public var fileName: String = "time-trackings.json"

  public init(fileName: String? = nil) {
    if let fileName {
      self.fileName = fileName
    }
  }
}

public class FileSystemPersistence: TrackingPersistenceProtocol {
  private let fileClient: FileSystemClient
  private let configuration: FileSystemPersistenceConfiguration

  public init(configuration: FileSystemPersistenceConfiguration, fileClient: FileSystemClient) {
    self.configuration = configuration
    self.fileClient = fileClient
  }

  public func loadTrackings() -> AnyPublisher<[TrackingEntity], Error> {
    guard let trackingsPath = configuration.trackingsPath else {
      return Fail(error: FileSystemPersistenceError.invalidFilePath(nil)).eraseToAnyPublisher()
    }

    return fileClient.loadFile(path: trackingsPath)
      .decode(type: [TrackingEntity].self, decoder: JSONDecoder())
      .mapError(FileSystemPersistenceError.decodingError)
      .eraseToAnyPublisher()
  }

  public func saveTrackings(trackings: [TrackingEntity]) -> AnyPublisher<Void, Error> {
    guard let trackingsPath = configuration.trackingsPath else {
      return Fail(error: FileSystemPersistenceError.invalidFilePath(nil)).eraseToAnyPublisher()
    }

    return Result<Data, Error> { try JSONEncoder().encode(trackings) }
      .publisher
      .mapError(FileSystemPersistenceError.encodingError)
      .flatMap { self.fileClient.saveFile(path: trackingsPath, data: $0) }
      .mapError(FileSystemPersistenceError.fileSavingError)
      .eraseToAnyPublisher()
  }
}
