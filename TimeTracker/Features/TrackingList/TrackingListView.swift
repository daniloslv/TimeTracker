//
//  TrackingList.swift
//  TimeTracker
//
//  Created by Danilo Souza on 06/02/23.
//

import ComposableArchitecture
import SwiftUI

struct TrackingListView: View {
    struct ViewState: Equatable {
        let state: TimeEntryCollectionReducer.State

        init(state: TimeEntryCollectionReducer.State) {
            self.state = state
        }
    }

    let store: StoreOf<TimeEntryCollectionReducer>
    @ObservedObject var viewStore: ViewStoreOf<TimeEntryCollectionReducer>

    init(store: StoreOf<TimeEntryCollectionReducer>) {
        self.store = store
        viewStore = ViewStoreOf<TimeEntryCollectionReducer>(store)
    }

    var body: some View {
        VStack {
            List {
                Button("Clear all") {
                    viewStore.send(.removeAll, animation: .default)
                }
                .buttonStyle(.action.variant(.negative))

                ForEachStore(
                    self.store.scope(
                        state: \.entries,
                        action: TimeEntryCollectionReducer.Action.timeTracking
                    ),
                    content: { TrackingCardSmall(store: $0).padding([.top, .bottom], 8) }
                )
            }
            .listStyle(.automatic)
            .toolbar {
                Button(action: { viewStore.send(.createNew(description: nil, status: .started), animation: .default) }) {
                    Label("Add new", systemImage: "plus.rectangle.fill")
                }
                .onAppear {
                    viewStore.send(.startDisplayTimer)
                }
            }
        }
    }
}

struct TrackingList_Previews: PreviewProvider {
    static var previews: some View {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)

        return TrackingListView(
            store: Store(
                initialState: .init(entries: [
                    .init(
                        entry: TrackingEntity(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                            description: .description("My important project"),
                            status: .stopped,
                            accumulatedTime: TrackingEntity.AccumulatedTime(),
                            createdAt: createdAt,
                            updatedAt: createdAt
                        )
                    ),
                    .init(
                        entry: TrackingEntity(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                            description: .description("Another Project."),
                            status: .started,
                            accumulatedTime: TrackingEntity.AccumulatedTime(),
                            createdAt: createdAt,
                            updatedAt: createdAt
                        )
                    ),
                ]),
                reducer: TimeEntryCollectionReducer()
            )
        )
    }
}
