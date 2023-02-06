//
//  App.swift
//  TimeTracker
//
//  Created by Danilo Souza on 04/02/23.
//

import ComposableArchitecture
import SwiftUI

struct ViewState: Equatable {
    let trackings: IdentifiedArrayOf<TimeEntryReducer.State>
    private let formatter: DateComponentsFormatter

    init(state: TimeEntryCollectionReducer.State) {
        trackings = state.entries
        formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.day, .hour, .minute, .second]
    }

    func titleToggleButton(entry: TimeEntryReducer.State) -> String {
        switch entry.entry.status {
        case .started:
            return "Stop"
        case .stopped:
            return "Start"
        }
    }

    func titleTrackingDescription(tracking: TimeEntryReducer.State) -> String {
        tracking.entry.description.value ?? "Name not set"
    }

    func trackingTime(tracking: TimeEntryReducer.State) -> String {
        formatter.string(from: tracking.entry.accumulatedTime.total) ?? ""
    }

    func timeFormattedLabel(tracking: TimeEntryReducer.State) -> String {
        let time = formatter.string(from: tracking.entry.accumulatedTime.total) ?? ""
        let name = tracking.entry.description.value ?? "Name not set"
        return [time, name].joined(separator: " ")
    }
}

enum ViewAction: Equatable {
    case startDisplayTimer
}

@main
struct TimeTrackerApp: App {
    let store: StoreOf<TimeEntryCollectionReducer>
    @ObservedObject var viewStore: ViewStore<ViewState, TimeEntryCollectionReducer.Action>

    init() {
        store = Store(
            initialState: TimeEntryCollectionReducer.State(entries: .init()),
            reducer: TimeEntryCollectionReducer()
        )
        viewStore = ViewStore(store.scope(state: ViewState.init))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                List {
                    ForEach(viewStore.trackings) { tracking in
                        Section {
                            HStack {
                                Image(systemName: "clock")
                                Text(viewStore.state.titleTrackingDescription(tracking: tracking))
                                Spacer()
                                Text(viewStore.state.trackingTime(tracking: tracking))
                            }
                            VStack(alignment: .center) {
                                Button(viewStore.state.titleToggleButton(entry: tracking)) {
                                    viewStore.send(.timeTracking(id: tracking.id, action: .toggleStatus))
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.roundedRectangle)
                                Button(role: .destructive) {
                                    viewStore.send(.remove(id: tracking.id))
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                }
                Button("Create new") {
                    viewStore.send(.createNew(description: nil, status: .started))
                }
            }
            .navigationTitle("Time Tracker")
            .onAppear {
                viewStore.send(.loadEntries)
                viewStore.send(.startDisplayTimer)
            }
        }
    }
}
