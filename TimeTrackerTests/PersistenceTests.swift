//
//  PersistenceTests.swift
//  TimeTrackerTests
//
//  Created by Danilo Souza on 05/02/23.
//

import Combine
@testable import TimeTracker
import XCTest

final class PersistenceTests: XCTestCase {
    private var filePersistence: FileSystemPersistence!
    private var mockTrackings: [TrackingEntity]!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        filePersistence = FileSystemPersistence(
            configuration: FileSystemPersistenceConfiguration(fileName: "testing-time-trackings.json"),
            fileClient: FileSystemClient()
        )
        mockTrackings = [
            mockTracking(id: 1),
            mockTracking(id: 2, description: "My Project"),
            mockTracking(id: 3, description: ""),
            mockTracking(id: 4, description: "My Task"),
        ]
        cancellables = []
    }

    // This will run a real file saving and file loading test.
    // They need to be done in this section:
    // First: save the file.
    // Second: load the saved file.
    // For tests, it will save and load to a file named `testing-time-trackings.json`.
    func test_loading_and_saving_tracking() throws {
        // Saving Step
        let trackings = mockTrackings!
        let savingExpectation = expectation(description: "save_trackings")
        var savingResultError: Error?
        var savingResultSuccess: Any?

        filePersistence.saveTrackings(trackings: trackings)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case let .failure(error):
                    savingResultError = error
                }
                savingExpectation.fulfill()
            } receiveValue: { complete in
                savingResultSuccess = complete
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 10)
        XCTAssertNil(savingResultError)
        XCTAssertNotNil(savingResultSuccess)

        // Loading Step
        let loadingExpectation = expectation(description: "load_trackings")
        var loadingResultError: Error?
        var loadingResultSuccess: Any?

        filePersistence.loadTrackings()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case let .failure(error):
                    loadingResultError = error
                }
                loadingExpectation.fulfill()
            } receiveValue: { trackings in
                loadingResultSuccess = trackings
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 10)
        XCTAssertNil(loadingResultError)
        XCTAssertNotNil(loadingResultSuccess)
    }

    private func mockTracking(id: Int, description: String? = nil) -> TrackingEntity {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let uuidString = {
            let stringId = "\(id)"
            let baseuuid = "00000000-0000-0000-0000-000000000000"
            return String(baseuuid.dropLast(stringId.count)) + stringId
        }()
        return TrackingEntity(
            id: UUID(uuidString: uuidString)!,
            description: .createWith(description: description),
            status: .started,
            accumulatedTime: TrackingEntity.AccumulatedTime(
                startDate: createdAt
            ),
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
