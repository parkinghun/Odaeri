//
//  UIControl+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 12/22/25.
//

import UIKit
import Combine

extension UIControl {
    func tapPublisher(for event: UIControl.Event = .touchUpInside) -> AnyPublisher<Void, Never> {
        Publishers.ControlEvent(control: self, event: event)
            .eraseToAnyPublisher()
    }

    func valuePublisher<T>(for event: UIControl.Event = .valueChanged, transform: @escaping (UIControl) -> T) -> AnyPublisher<T, Never> {
        Publishers.ControlValueEvent(control: self, event: event, transform: transform)
            .eraseToAnyPublisher()
    }
}

extension Publishers {
    struct ControlEvent: Publisher {
        typealias Output = Void
        typealias Failure = Never

        let control: UIControl
        let event: UIControl.Event

        func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
            let subscription = Subscription(subscriber: subscriber, control: control, event: event)
            subscriber.receive(subscription: subscription)
        }
    }

    struct ControlValueEvent<T>: Publisher {
        typealias Output = T
        typealias Failure = Never

        let control: UIControl
        let event: UIControl.Event
        let transform: (UIControl) -> T

        func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
            let subscription = ValueSubscription(subscriber: subscriber, control: control, event: event, transform: transform)
            subscriber.receive(subscription: subscription)
        }
    }
}

extension Publishers.ControlEvent {
    private final class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Void, S.Failure == Never {
        private var subscriber: S?
        private let control: UIControl
        private let event: UIControl.Event

        init(subscriber: S, control: UIControl, event: UIControl.Event) {
            self.subscriber = subscriber
            self.control = control
            self.event = event

            control.addTarget(self, action: #selector(eventOccurred), for: event)
        }

        func request(_ demand: Subscribers.Demand) {
        }

        func cancel() {
            subscriber = nil
            control.removeTarget(self, action: #selector(eventOccurred), for: event)
        }

        @objc private func eventOccurred() {
            _ = subscriber?.receive()
        }
    }
}

extension Publishers.ControlValueEvent {
    private final class ValueSubscription<S: Subscriber, T>: Combine.Subscription where S.Input == T, S.Failure == Never {
        private var subscriber: S?
        private let control: UIControl
        private let event: UIControl.Event
        private let transform: (UIControl) -> T

        init(subscriber: S, control: UIControl, event: UIControl.Event, transform: @escaping (UIControl) -> T) {
            self.subscriber = subscriber
            self.control = control
            self.event = event
            self.transform = transform

            control.addTarget(self, action: #selector(eventOccurred), for: event)
        }

        func request(_ demand: Subscribers.Demand) {
        }

        func cancel() {
            subscriber = nil
            control.removeTarget(self, action: #selector(eventOccurred), for: event)
        }

        @objc private func eventOccurred() {
            let value = transform(control)
            _ = subscriber?.receive(value)
        }
    }
}
