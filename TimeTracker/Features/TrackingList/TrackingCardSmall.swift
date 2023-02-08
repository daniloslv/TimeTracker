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
        let entry: TrackingEntity
        var deleteIcon = "trash"
        var isActive: Bool { entry.status == .started }
        var timeText: String { formatter.timeStringFrom(entry.accumulatedTime.total) }
        var creationText: String { formatter.dateStringFrom(entry.createdAt) }
        var showDeleteButton: Bool { !isActive }
        var accentColor: Color { isActive ? .green : .gray }
        var alphaForDelete: Double { boolAlpha(showDeleteButton) }

        var description: String

        var toggleButtonText: String {
            switch entry.status {
            case .started: return "Pause"
            case .stopped: return "Start"
            }
        }

        var actionButtonStyle: ActionStyle {
            isActive
                ? .action.variant(.primary)
                : .action.variant(.secondary)
        }

        private let formatter = TimeFormatter.liveValue

        init(state: TimeEntryReducer.State) {
            entry = state.entry
            description = state.entry.description.value ?? ""
        }

        func boolAlpha(_ value: Bool) -> Double {
            value ? 1.0 : 0.0
        }
    }

    let store: StoreOf<TimeEntryReducer>
    @ObservedObject
    var viewStore: ViewStore<ViewState, TimeEntryReducer.Action>
    var descriptionLineStore: ViewStore<DescriptionLineView.ViewState, DescriptionLineView.Action> {
        ViewStore(
            store,
            observe: DescriptionLineView.ViewState.init,
            send: { TimeEntryReducer.Action.updateDescription($0.value) }
        )
    }

    init(store: StoreOf<TimeEntryReducer>) {
        self.store = store
        viewStore = ViewStore(store.scope(state: ViewState.init))
    }

    var body: some View {
        VStack {
            HStack {
                DescriptionLineView(store: descriptionLineStore)
                TimeDisplayView(time: viewStore.timeText)
            }

            HStack(alignment: .bottom) {
                DateCreationView(date: viewStore.creationText)
                Spacer()
                HStack {
                    Button(role: .destructive) {
                        viewStore.send(.remove, animation: .default)
                    } label: { Image(systemName: viewStore.deleteIcon) }
                        .buttonStyle(.action.variant(.negative))
                        .opacity(viewStore.alphaForDelete)

                    Button(viewStore.state.toggleButtonText) {
                        viewStore.send(.toggleStatus, animation: .default)
                    }
                    .buttonStyle(viewStore.actionButtonStyle)
                }
            }
        }
    }
}

struct DateCreationView: View {
    var date: String

    init(date: String) {
        self.date = date
    }

    var body: some View {
        Text(date)
            .monospacedDigit()
            .font(.caption)
            .foregroundColor(.gray)
    }
}

struct TimeDisplayView: View {
    var time: String

    init(time: String) {
        self.time = time
    }

    var body: some View {
        Text(time)
            .font(.footnote.monospacedDigit())
            .foregroundColor(.gray)
    }
}

struct DescriptionLineView: View {
    struct ViewState: Equatable {
        var description: String
        var placeholder: String
        var icon: String
        var isActive: Bool

        init(state: TimeEntryReducer.State) {
            description = state.entry.description.value ?? "+ Add description"
            placeholder = "I'm working on..."
            icon = "clock"
            isActive = state.entry.status == .started
        }

        var accentColor: Color {
            isActive ? .green : .gray
        }
    }

    enum Action: Equatable {
        case edit(String)

        var value: String {
            switch self {
            case let .edit(value): return value
            }
        }
    }

    @ObservedObject
    var viewStore: ViewStore<ViewState, Action>

    init(store: ViewStore<ViewState, Action>) {
        viewStore = store
    }

    var body: some View {
        Label(
            title: {
                TextField(
                    viewStore.placeholder,
                    text: viewStore.binding(get: \.description, send: Action.edit)
                )
                .font(.subheadline)
            },
            icon: { Image(systemName: viewStore.icon) }
        )
        .foregroundColor(viewStore.accentColor)
    }
}

struct TrackingCardSmall_Previews: PreviewProvider {
    static var previews: some View {
        let createdAt = Date(timeIntervalSince1970: 1_111_100_000)
        let tracking = TrackingEntity(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            description: .unnamed,
            status: .stopped,
            accumulatedTime: TrackingEntity.AccumulatedTime(
                total: 10000,
                accumulatedSession: 20000,
                currentSession: 15000,
                startDate: createdAt
            ),
            createdAt: createdAt,
            updatedAt: createdAt
        )

        return VStack {
            TrackingCardSmall(store: .init(
                initialState: .init(entry: tracking),
                reducer: TimeEntryReducer()
            ))
            .padding()
            .border(.gray.opacity(0.3))
        }
        .padding()
        .frame(width: /*@START_MENU_TOKEN@*/400.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/140.0/*@END_MENU_TOKEN@*/)
    }
}

struct ActionStyle: ButtonStyle {
    var styleVariant: Variant

    public init() {
        styleVariant = .primary
    }

    public init(variant: Variant) {
        styleVariant = variant
    }

    public func makeBody(configuration: ActionStyle.Configuration) -> some View {
        StyledButton(configuration: configuration, variant: styleVariant)
    }

    public enum Variant {
        case accent
        case primary
        case secondary
        case negative
    }

    public enum Style {
        case fill
        case outline
    }

    struct StyledButton: View {
        let configuration: ActionStyle.Configuration
        let variant: Variant

        init(configuration: ActionStyle.Configuration) {
            self.configuration = configuration
            variant = .primary
        }

        init(configuration: ActionStyle.Configuration, variant: Variant) {
            self.configuration = configuration
            self.variant = variant
        }

        var foreground: Color {
            .white
        }

        var background: Color {
            switch variant {
            case .accent: return .blue
            case .primary: return .black
            case .secondary: return .gray
            case .negative: return .red
            }
        }

        var body: some View {
            configuration.label
                .font(.subheadline)
                .foregroundColor(foreground)
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                .background(
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
                        .fill(background)
                )
                .compositingGroup()
        }
    }
}

extension ButtonStyle where Self == ActionStyle {
    static var action: ActionStyle { ActionStyle() }

    func variant(_ newVariant: ActionStyle.Variant) -> ActionStyle {
        var copy = self
        copy.styleVariant = newVariant
        return copy
    }
}
