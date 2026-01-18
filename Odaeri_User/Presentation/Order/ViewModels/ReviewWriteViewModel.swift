//
//  ReviewWriteViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Foundation
import Combine

final class ReviewWriteViewModel: BaseViewModel, ViewModelType {
    private enum Constant {
        static let minContentLength = 10
    }

    struct Input {
        let ratingSelected: AnyPublisher<Int, Never>
        let contentChanged: AnyPublisher<String, Never>
        let submitTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let header: AnyPublisher<ReviewWriteHeader, Never>
        let currentRating: AnyPublisher<Int, Never>
        let isSubmitEnabled: AnyPublisher<Bool, Never>
        let submitRequested: AnyPublisher<ReviewWritePayload, Never>
    }

    let mode: ReviewWriteMode

    private let ratingSubject: CurrentValueSubject<Int, Never>
    private let contentSubject = CurrentValueSubject<String, Never>("")
    private let submitSubject = PassthroughSubject<Void, Never>()

    init(mode: ReviewWriteMode) {
        self.mode = mode
        self.ratingSubject = CurrentValueSubject<Int, Never>(mode.initialRating)
    }

    func transform(input: Input) -> Output {
        let mode = self.mode

        input.ratingSelected
            .sink { [weak self] rating in
                self?.ratingSubject.send(rating)
            }
            .store(in: &cancellables)

        input.contentChanged
            .sink { [weak self] content in
                self?.contentSubject.send(content)
            }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] in
                self?.submitSubject.send(())
            }
            .store(in: &cancellables)

        let header = Just(makeHeader())
            .eraseToAnyPublisher()

        let isSubmitEnabled = Publishers.CombineLatest(ratingSubject, contentSubject)
            .map { rating, content in
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return rating > 0 && trimmed.count >= Constant.minContentLength
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let submitRequested = submitSubject
            .withLatestFrom(Publishers.CombineLatest(ratingSubject, contentSubject))
            .map { _, combined -> ReviewWritePayload in
                let (rating, content) = combined
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return ReviewWritePayload(
                    mode: mode,
                    rating: rating,
                    content: trimmed
                )
            }
            .eraseToAnyPublisher()

        return Output(
            header: header,
            currentRating: ratingSubject.eraseToAnyPublisher(),
            isSubmitEnabled: isSubmitEnabled,
            submitRequested: submitRequested
        )
    }
}

struct ReviewWriteHeader {
    let storeName: String
    let storeImageUrl: String?
    let menuSummary: String
}

struct ReviewWritePayload {
    let mode: ReviewWriteMode
    let rating: Int
    let content: String
}

private extension ReviewWriteViewModel {
    func makeHeader() -> ReviewWriteHeader {
        let order = mode.order
        let menuSummary = makeMenuSummary(from: order)
        return ReviewWriteHeader(
            storeName: order.store.name,
            storeImageUrl: order.store.storeImageUrls.first,
            menuSummary: menuSummary
        )
    }

    func makeMenuSummary(from order: OrderListItemEntity) -> String {
        guard let first = order.orderMenuList.first else { return "메뉴 없음" }
        if order.orderMenuList.count > 1 {
            return "\(first.menu.name) 외 \(order.orderMenuList.count - 1)건"
        }
        return first.menu.name
    }
}
