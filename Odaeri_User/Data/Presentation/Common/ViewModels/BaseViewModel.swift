//
//  BaseViewModel.swift
//  Odaeri
//
//  Created by 박성훈 on 12/16/25.
//

import Foundation
import Combine

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

class BaseViewModel {
    var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.removeAll()
    }
}
