//
//  TrackingCardView.swift
//  TimeTracker
//
//  Created by Danilo Souza on 06/02/23.
//

import ComposableArchitecture
import SwiftUI

extension TrackingCardView {
  struct ViewState: Equatable {
    var entry: TrackingEntity
    var isActive: Bool
    var descriptionText: String
    var timeText: String
    var creationDateText: String
    var placeholderText: String = "What are you doing?"
    var toggleButtonText: String { entry.status == .started ? "Pause" : "Start" }
    var showDeleteButton: Bool

    init(state: TimeEntry.State) {
      entry = state.entry
      descriptionText = state.entry.description.value ?? "+ Add description"
      timeText = TimeFormatter.liveValue.timeStringFrom(state.entry.accumulatedTime.total)
      isActive = state.entry.status == .started
      creationDateText = TimeFormatter.liveValue.dateStringFrom(state.entry.createdAt)
      showDeleteButton = !isActive
    }
  }
}

struct TrackingCardView: View {
  typealias Action = TimeEntry.Action

  let store: StoreOf<TimeEntry>
  @ObservedObject var viewStore: ViewStore<ViewState, Action>

  init(store: StoreOf<TimeEntry>) {
    self.store = store
    viewStore = ViewStore(store, observe: ViewState.init)
  }

  var body: some View {
    VStack {
      HStack {
        Image(systemName: "clock")
          .foregroundColor(viewStore.isActive ? .green : .gray)
        TextField(
          viewStore.placeholderText,
          text: viewStore.binding(
            get: \.descriptionText,
            send: Action.updateDescription
          )
        )
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
          .opacity(viewStore.showDeleteButton ? 1 : 0)

          Button(viewStore.toggleButtonText) {
            viewStore.send(.toggleStatus, animation: .default)
          }
          .buttonStyle(.bordered)
          .buttonBorderShape(.roundedRectangle)
        }
      }
    }
  }
}

// MARK: - SwiftUI Preview

struct TrackingCardSmall_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      TrackingCardView(
        store: .init(
          initialState: .init(
            entry:
            TrackingEntity(
              id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
              description: .unnamed,
              status: .started,
              accumulatedTime: TrackingEntity.AccumulatedTime(
                total: 10_000,
                accumulatedSession: 20_000,
                currentSession: 15_000,
                startDate: Date(timeIntervalSince1970: 1_111_100_000)
              ),
              createdAt: Date(timeIntervalSince1970: 1_111_100_000),
              updatedAt: Date(timeIntervalSince1970: 1_111_100_000)
            )
          ),
          reducer: TimeEntry()
        )
      )
      .previewDisplayName("Started")

      TrackingCardView(
        store: .init(
          initialState: .init(
            entry:
            TrackingEntity(
              id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
              description: .unnamed,
              status: .stopped,
              accumulatedTime: TrackingEntity.AccumulatedTime(
                total: 10_000,
                accumulatedSession: 20_000,
                currentSession: 15_000,
                startDate: Date(timeIntervalSince1970: 1_111_100_000)
              ),
              createdAt: Date(timeIntervalSince1970: 1_111_100_000),
              updatedAt: Date(timeIntervalSince1970: 1_111_100_000)
            )
          ),
          reducer: TimeEntry()
        )
      )
      .previewDisplayName("Stopped")
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
  }
}
