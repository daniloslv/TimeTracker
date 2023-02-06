//
//  TrackingCardSmall.swift
//  TimeTracker
//
//  Created by Danilo Souza on 06/02/23.
//

import ComposableArchitecture
import SwiftUI

struct TrackingCardSmall: View {
    struct ViewState: Equatable {
        let state: TimeEntryReducer.State
        var editingDescriptionText: String
        private let formatter = TimeFormatter.liveValue

        init(state: TimeEntryReducer.State) {
            self.state = state
            editingDescriptionText = state.entry.description.value ?? "+ Add description"
        }

        var toggleButtonText: String {
            switch state.entry.status {
            case .started:
                return "Pause"
            case .stopped:
                return "Start"
            }
        }

        var timeText: String {
            formatter.timeStringFrom(state.entry.accumulatedTime.total)
        }

        var creationDateText: String {
            formatter.dateStringFrom(state.entry.createdAt)
        }

        var isActive: Bool {
            state.entry.status == .started
        }

        var showDeleteButton: Bool {
            !isActive
        }
    }

    let store: StoreOf<TimeEntryReducer>
    @ObservedObject var viewStore: ViewStore<ViewState, TimeEntryReducer.Action>

    init(store: StoreOf<TimeEntryReducer>) {
        self.store = store
        viewStore = ViewStore(store.scope(state: ViewState.init))
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(viewStore.isActive ? .green : .gray)
                TextField(
                    "I'm working on...",
                    text: viewStore.binding(
                        get: \.editingDescriptionText,
                        send: { value in .updateDescription(value) }
                    )
                ) { viewStore.send(.updateDescription(viewStore.editingDescriptionText)) }
                    .foregroundColor(viewStore.isActive ? .green : .gray)
                Text(viewStore.state.timeText)
                    .monospacedDigit()
                    .font(.body)
                    .foregroundColor(.gray)
            }
            HStack(alignment: .bottom) {
                Text(viewStore.state.creationDateText)
                    .monospacedDigit()
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                HStack {
                    Button(role: .destructive) {
                        viewStore.send(.remove, animation: .default)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                    .opacity(viewStore.state.showDeleteButton ? 1 : 0)

                    Button(viewStore.state.toggleButtonText) {
                        viewStore.send(.toggleStatus, animation: .default)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                }
            }
        }
    }
}

struct TrackingCardSmall_Previews: PreviewProvider {
    static var previews: some View {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        return TrackingCardSmall(
            store: .init(
                initialState: .init(
                    entry:
                    TrackingEntity(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                        description: .unnamed,
                        status: .started,
                        accumulatedTime: TrackingEntity.AccumulatedTime(
                            total: 10000,
                            accumulatedSession: 20000,
                            currentSession: 15000,
                            startDate: createdAt
                        ),
                        createdAt: createdAt,
                        updatedAt: createdAt
                    )
                ),
                reducer: TimeEntryReducer()
            )
        )
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}
