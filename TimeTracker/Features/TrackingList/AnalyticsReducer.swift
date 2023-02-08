//
//  AnalyticsReducer.swift
//  TimeTracker
//
//  Created by Danilo Souza on 08/02/23.
//

import ComposableArchitecture

extension ReducerProtocol {
    public func analytics<Trigger: Equatable & AnalyticsEventProducer>(
        isEnabled: @escaping (State, Action) -> Bool,
        triggerOnChageOf trigger: @escaping (State) -> Trigger
    ) -> some ReducerProtocol<State, Action> {
        Analytics(base: self, isEnabled: isEnabled, trigger: trigger)
    }
}

public protocol AnalyticsEventProducer {
    func produceAnalyticsEvent() -> String
}

private struct Analytics<Base: ReducerProtocol, Trigger: Equatable & AnalyticsEventProducer>: ReducerProtocol {
    let base: Base
    let isEnabled: (Base.State, Base.Action) -> Bool
    let trigger: (Base.State) -> Trigger
    
    @Dependency(\.analyticsEngine) var analyticsEngine
    
    var body: some ReducerProtocol<Base.State, Base.Action> {
        self.base.onChange(of: self.trigger) { childStateBefore, childStateAfter, state, action in
            guard self.isEnabled(state, action) else { return .none }
            return .fireAndForget {
                await self.analyticsEngine.track(childStateAfter.produceAnalyticsEvent())
            }
        }
    }
}

public struct AnalyticsEngine {
    public let track: @Sendable (String) async -> Void
}
enum AnalyticsDependency: DependencyKey, TestDependencyKey {
    static let liveValue = AnalyticsEngine(track: { event in print("live tracking:", event) })
    static let testValue = AnalyticsEngine(track: { event in print("test tracking:", event) })
}
extension DependencyValues {
    public var analyticsEngine: AnalyticsEngine {
        get { self[AnalyticsDependency.self] }
        set { self[AnalyticsDependency.self] = newValue }
    }
}

extension ReducerProtocol {
  @inlinable
  public func onChange<ChildState: Equatable>(
    of toLocalState: @escaping (State) -> ChildState,
    perform additionalEffects: @escaping (ChildState, inout State, Action) -> Effect<
      Action, Never
    >
  ) -> some ReducerProtocol<State, Action> {
    self.onChange(of: toLocalState) { additionalEffects($1, &$2, $3) }
  }

  @inlinable
  public func onChange<ChildState: Equatable>(
    of toLocalState: @escaping (State) -> ChildState,
    perform additionalEffects: @escaping (ChildState, ChildState, inout State, Action) -> Effect<
      Action, Never
    >
  ) -> some ReducerProtocol<State, Action> {
    ChangeReducer(base: self, toLocalState: toLocalState, perform: additionalEffects)
  }
}

@usableFromInline
struct ChangeReducer<Base: ReducerProtocol, ChildState: Equatable>: ReducerProtocol {
  @usableFromInline
  let base: Base

  @usableFromInline
  let toLocalState: (Base.State) -> ChildState

  @usableFromInline
  let perform:
    (ChildState, ChildState, inout Base.State, Base.Action) -> Effect<
      Base.Action, Never
    >

  @usableFromInline
  init(
    base: Base,
    toLocalState: @escaping (Base.State) -> ChildState,
    perform: @escaping (ChildState, ChildState, inout Base.State, Base.Action) -> Effect<
      Base.Action, Never
    >
  ) {
    self.base = base
    self.toLocalState = toLocalState
    self.perform = perform
  }

  @inlinable
  public func reduce(into state: inout Base.State, action: Base.Action) -> Effect<
    Base.Action, Never
  > {
    let previousLocalState = self.toLocalState(state)
    let effects = self.base.reduce(into: &state, action: action)
    let localState = self.toLocalState(state)

    return previousLocalState != localState
      ? .merge(effects, self.perform(previousLocalState, localState, &state, action))
      : effects
  }
}


/**
extension ReducerProtocol {
  public func haptics<Trigger: Equatable>(
    isEnabled: @escaping (State) -> Bool,
    triggerOnChangeOf trigger: @escaping (State) -> Trigger
  ) -> some ReducerProtocol<State, Action> {
    Haptics(base: self, isEnabled: isEnabled, trigger: trigger)
  }
}

private struct Haptics<Base: ReducerProtocol, Trigger: Equatable>: ReducerProtocol {
  let base: Base
  let isEnabled: (Base.State) -> Bool
  let trigger: (Base.State) -> Trigger

  @Dependency(\.feedbackGenerator) var feedbackGenerator

  var body: some ReducerProtocol<Base.State, Base.Action> {
    self.base.onChange(of: self.trigger) { _, _, state, _ in
      guard self.isEnabled(state) else { return .none }
      return .fireAndForget { await self.feedbackGenerator.selectionChanged() }
    }
  }
}

*/
