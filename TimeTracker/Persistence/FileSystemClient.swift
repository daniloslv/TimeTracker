//
//  FileSystemClient.swift
//  TimeTracker
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
import Foundation

public class FileSystemClient {
    func loadFile(path: URL) -> AnyPublisher<Data, Error> {
        Result<Data, Error> {
            try Data(contentsOf: path)
        }
        .publisher
        .eraseToAnyPublisher()
    }

    func saveFile(path: URL, data: Data) -> AnyPublisher<Void, Error> {
        Result<Void, Error> {
            try data.write(to: path)
        }
        .publisher
        .eraseToAnyPublisher()
    }

    func removeFile(path: URL) -> AnyPublisher<Void, Error> {
        Result<Void, Error> {
            try FileManager.default.removeItem(at: path)
        }
        .publisher
        .eraseToAnyPublisher()
    }
}
