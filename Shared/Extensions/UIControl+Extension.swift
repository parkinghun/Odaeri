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
