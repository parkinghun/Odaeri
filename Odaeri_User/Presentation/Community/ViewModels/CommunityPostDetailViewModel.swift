//
//  CommunityPostDetailViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Combine
import Foundation

final class CommunityPostDetailViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let commentToggleTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let post: AnyPublisher<CommunityPostEntity?, Never>
        let comments: AnyPublisher<[CommunityPostCommentEntity], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    let postId: String
    private let postRepository: CommunityPostRepository
    private let postSubject = CurrentValueSubject<CommunityPostEntity?, Never>(nil)
    private let commentsSubject = CurrentValueSubject<[CommunityPostCommentEntity], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()

    init(
        postId: String,
        postRepository: CommunityPostRepository = CommunityPostRepositoryImpl()
    ) {
        self.postId = postId
        self.postRepository = postRepository
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.fetchPostDetail()
            }
            .store(in: &cancellables)

        input.commentToggleTapped
            .sink { [weak self] commentId in
                self?.toggleCommentExpansion(commentId: commentId)
            }
            .store(in: &cancellables)

        return Output(
            post: postSubject.eraseToAnyPublisher(),
            comments: commentsSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    private func fetchPostDetail() {
        isLoadingSubject.send(true)

        postRepository.fetchPostDetail(postId: postId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] post in
                    self?.postSubject.send(post)
                    self?.commentsSubject.send(self?.prepareComments(post.comments) ?? [])
                }
            )
            .store(in: &cancellables)
    }

    private func prepareComments(_ comments: [CommunityPostCommentEntity]) -> [CommunityPostCommentEntity] {
        return comments.map { comment in
            var updated = comment
            updated.isExpanded = false
            return updated
        }
    }

    private func toggleCommentExpansion(commentId: String) {
        var comments = commentsSubject.value
        guard let index = comments.firstIndex(where: { $0.commentId == commentId }) else { return }
        comments[index].isExpanded.toggle()
        commentsSubject.send(comments)
    }
}
