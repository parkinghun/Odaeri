//
//  CommunityPostDetailViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/17/26.
//

import Combine
import Foundation

final class CommunityPostDetailViewModel: BaseViewModel, ViewModelType {
    weak var coordinator: CommunityCoordinator?

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let commentToggleTapped: AnyPublisher<String, Never>
        let likeToggleTapped: AnyPublisher<Bool, Never>
        let addComment: AnyPublisher<(parentId: String?, content: String), Never>
        let updateComment: AnyPublisher<(commentId: String, content: String), Never>
        let deleteComment: AnyPublisher<String, Never>
    }

    struct Output {
        let post: AnyPublisher<CommunityPostEntity?, Never>
        let comments: AnyPublisher<[CommunityPostCommentEntity], Never>
        let commentCount: AnyPublisher<Int, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    let postId: String
    private let postRepository: CommunityPostRepository
    private let commentRepository: CommunityCommentRepository
    private let userManager: UserManager
    private let notificationCenter: NotificationCenter
    private let postSubject = CurrentValueSubject<CommunityPostEntity?, Never>(nil)
    private let commentsSubject = CurrentValueSubject<[CommunityPostCommentEntity], Never>([])

    init(
        postId: String,
        postRepository: CommunityPostRepository,
        commentRepository: CommunityCommentRepository,
        userManager: UserManager,
        notificationCenter: NotificationCenter
    ) {
        self.postId = postId
        self.postRepository = postRepository
        self.commentRepository = commentRepository
        self.userManager = userManager
        self.notificationCenter = notificationCenter
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

        input.likeToggleTapped
            .sink { [weak self] isLiked in
                self?.toggleLike(isLiked: isLiked)
            }
            .store(in: &cancellables)

        input.addComment
            .sink { [weak self] parentId, content in
                self?.addComment(parentId: parentId, content: content)
            }
            .store(in: &cancellables)

        input.updateComment
            .sink { [weak self] commentId, content in
                self?.updateComment(commentId: commentId, content: content)
            }
            .store(in: &cancellables)

        input.deleteComment
            .sink { [weak self] commentId in
                self?.deleteComment(commentId: commentId)
            }
            .store(in: &cancellables)

        return Output(
            post: postSubject.eraseToAnyPublisher(),
            comments: commentsSubject.eraseToAnyPublisher(),
            commentCount: commentsSubject.map { [weak self] in self?.getTotalCommentCount($0) ?? 0 }.eraseToAnyPublisher(),
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
                    let comments = self?.prepareComments(post.comments) ?? []
                    self?.commentsSubject.send(comments)
                    self?.postSubject.send(self?.buildPost(from: post, comments: comments) ?? post)
                }
            )
            .store(in: &cancellables)
    }

    private func prepareComments(_ comments: [CommunityPostCommentEntity]) -> [CommunityPostCommentEntity] {
        return comments.map { comment in
            CommunityPostCommentEntity(
                commentId: comment.commentId,
                content: comment.content,
                createdAt: comment.createdAt,
                creator: comment.creator,
                replies: comment.replies,
                isMine: comment.isMine,
                isExpanded: false
            )
        }
    }

    private func toggleCommentExpansion(commentId: String) {
        var comments = commentsSubject.value
        guard let index = comments.firstIndex(where: { $0.commentId == commentId }) else { return }
        let comment = comments[index]
        comments[index] = CommunityPostCommentEntity(
            commentId: comment.commentId,
            content: comment.content,
            createdAt: comment.createdAt,
            creator: comment.creator,
            replies: comment.replies,
            isMine: comment.isMine,
            isExpanded: !comment.isExpanded
        )
        commentsSubject.send(comments)
    }

    private func toggleLike(isLiked: Bool) {
        guard let currentPost = postSubject.value else { return }

        let newCount = max(0, currentPost.likeCount + (isLiked ? 1 : -1))
        let currentComments = commentsSubject.value
        let optimisticPost = buildPost(
            from: currentPost,
            isLike: isLiked,
            likeCount: newCount,
            comments: currentComments
        )

        postSubject.send(optimisticPost)
        notifyInteractionUpdate(from: optimisticPost, commentCount: currentComments.count)

        postRepository.toggleLike(postId: postId, status: isLiked)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                        self?.revertLike(previousPost: currentPost)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func revertLike(previousPost: CommunityPostEntity) {
        let currentComments = commentsSubject.value
        let reverted = buildPost(
            from: previousPost,
            isLike: previousPost.isLike,
            likeCount: previousPost.likeCount,
            comments: currentComments
        )
        postSubject.send(reverted)
        notifyInteractionUpdate(from: reverted, commentCount: currentComments.count)
    }

    private func addComment(parentId: String?, content: String) {
        let currentComments = commentsSubject.value
        let currentPost = postSubject.value

        let currentUserId = userManager.currentUser?.userId ?? ""
        let currentUserNick = userManager.currentUser?.nick ?? ""
        let currentUserProfileImage = userManager.currentUser?.profileImage

        let tempComment: CommunityPostCommentEntity
        if let parentId = parentId {
            var updatedComments = currentComments
            if let parentIndex = updatedComments.firstIndex(where: { $0.commentId == parentId }) {
                let tempReply = CommunityPostReplyEntity(
                    commentId: UUID().uuidString,
                    content: content,
                    createdAt: Date(),
                    creator: CreatorEntity(userId: currentUserId, nick: currentUserNick, profileImage: currentUserProfileImage),
                    isMine: true
                )
                var parent = updatedComments[parentIndex]
                var replies = parent.replies
                replies.append(tempReply)
                parent = CommunityPostCommentEntity(
                    commentId: parent.commentId,
                    content: parent.content,
                    createdAt: parent.createdAt,
                    creator: parent.creator,
                    replies: replies,
                    isMine: parent.isMine,
                    isExpanded: true
                )
                updatedComments[parentIndex] = parent
                commentsSubject.send(updatedComments)
                if let currentPost = currentPost {
                    let updated = buildPost(from: currentPost, comments: updatedComments)
                    postSubject.send(updated)
                    notifyInteractionUpdate(from: updated, commentCount: getTotalCommentCount(updatedComments))
                }
            }
        } else {
            tempComment = CommunityPostCommentEntity(
                commentId: UUID().uuidString,
                content: content,
                createdAt: Date(),
                creator: CreatorEntity(userId: currentUserId, nick: currentUserNick, profileImage: currentUserProfileImage),
                replies: [],
                isMine: true,
                isExpanded: false
            )
            var updatedComments = currentComments
            updatedComments.append(tempComment)
            commentsSubject.send(updatedComments)
            if let currentPost = currentPost {
                let updated = buildPost(from: currentPost, comments: updatedComments)
                postSubject.send(updated)
                notifyInteractionUpdate(from: updated, commentCount: getTotalCommentCount(updatedComments))
            }
        }

        commentRepository.addComment(postId: postId, parentId: parentId, content: content)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                        self?.commentsSubject.send(currentComments)
                        if let currentPost = currentPost {
                            self?.postSubject.send(currentPost)
                            self?.notifyInteractionUpdate(from: currentPost, commentCount: self?.getTotalCommentCount(currentComments) ?? 0)
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func updateComment(commentId: String, content: String) {
        let currentComments = commentsSubject.value
        let currentPost = postSubject.value

        var updatedComments = currentComments
        var originalComment: CommunityPostCommentEntity?
        var originalReply: CommunityPostReplyEntity?

        if let commentIndex = updatedComments.firstIndex(where: { $0.commentId == commentId }) {
            originalComment = updatedComments[commentIndex]
            var comment = updatedComments[commentIndex]
            comment = CommunityPostCommentEntity(
                commentId: comment.commentId,
                content: content,
                createdAt: comment.createdAt,
                creator: comment.creator,
                replies: comment.replies,
                isMine: comment.isMine,
                isExpanded: comment.isExpanded
            )
            updatedComments[commentIndex] = comment
        } else {
            for (parentIndex, parent) in updatedComments.enumerated() {
                if let replyIndex = parent.replies.firstIndex(where: { $0.commentId == commentId }) {
                    originalReply = parent.replies[replyIndex]
                    var parent = parent
                    var replies = parent.replies
                    replies[replyIndex] = CommunityPostReplyEntity(
                        commentId: replies[replyIndex].commentId,
                        content: content,
                        createdAt: replies[replyIndex].createdAt,
                        creator: replies[replyIndex].creator,
                        isMine: replies[replyIndex].isMine
                    )
                    parent = CommunityPostCommentEntity(
                        commentId: parent.commentId,
                        content: parent.content,
                        createdAt: parent.createdAt,
                        creator: parent.creator,
                        replies: replies,
                        isMine: parent.isMine,
                        isExpanded: parent.isExpanded
                    )
                    updatedComments[parentIndex] = parent
                    break
                }
            }
        }

        commentsSubject.send(updatedComments)
        if let currentPost = currentPost {
            let updated = buildPost(from: currentPost, comments: updatedComments)
            postSubject.send(updated)
        }

        commentRepository.updateComment(postId: postId, commentId: commentId, content: content)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                        self?.commentsSubject.send(currentComments)
                        if let currentPost = currentPost {
                            self?.postSubject.send(currentPost)
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func deleteComment(commentId: String) {
        let currentComments = commentsSubject.value
        let currentPost = postSubject.value

        var updatedComments = currentComments

        if let commentIndex = updatedComments.firstIndex(where: { $0.commentId == commentId }) {
            updatedComments.remove(at: commentIndex)
        } else {
            for (parentIndex, parent) in updatedComments.enumerated() {
                if let replyIndex = parent.replies.firstIndex(where: { $0.commentId == commentId }) {
                    var parent = parent
                    var replies = parent.replies
                    replies.remove(at: replyIndex)
                    parent = CommunityPostCommentEntity(
                        commentId: parent.commentId,
                        content: parent.content,
                        createdAt: parent.createdAt,
                        creator: parent.creator,
                        replies: replies,
                        isMine: parent.isMine,
                        isExpanded: parent.isExpanded
                    )
                    updatedComments[parentIndex] = parent
                    break
                }
            }
        }

        commentsSubject.send(updatedComments)
        if let currentPost = currentPost {
            let updated = buildPost(from: currentPost, comments: updatedComments)
            postSubject.send(updated)
            notifyInteractionUpdate(from: updated, commentCount: getTotalCommentCount(updatedComments))
        }

        commentRepository.deleteComment(postId: postId, commentId: commentId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                        self?.commentsSubject.send(currentComments)
                        if let currentPost = currentPost {
                            self?.postSubject.send(currentPost)
                            self?.notifyInteractionUpdate(from: currentPost, commentCount: self?.getTotalCommentCount(currentComments) ?? 0)
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func getTotalCommentCount(_ comments: [CommunityPostCommentEntity]) -> Int {
        return comments.reduce(0) { $0 + 1 + $1.replies.count }
    }

    private func updatePostComments(_ comments: [CommunityPostCommentEntity]) {
        guard let currentPost = postSubject.value else { return }
        let updated = buildPost(from: currentPost, comments: comments)
        postSubject.send(updated)
        notifyInteractionUpdate(from: updated, commentCount: comments.count)
    }

    private func notifyInteractionUpdate(from post: CommunityPostEntity, commentCount: Int) {
        let info = CommunityPostInteractionUpdateInfo(
            postId: post.postId,
            isLiked: post.isLike,
            likeCount: post.likeCount,
            commentCount: commentCount
        )
        notificationCenter.post(
            name: .communityPostInteractionDidUpdate,
            object: info
        )
    }

    private func buildPost(
        from post: CommunityPostEntity,
        isLike: Bool? = nil,
        likeCount: Int? = nil,
        comments: [CommunityPostCommentEntity]? = nil
    ) -> CommunityPostEntity {
        CommunityPostEntity(
            postId: post.postId,
            category: post.category,
            title: post.title,
            content: post.content,
            store: post.store,
            geolocation: post.geolocation,
            creator: post.creator,
            files: post.files,
            isLike: isLike ?? post.isLike,
            likeCount: likeCount ?? post.likeCount,
            comments: comments ?? post.comments,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt
        )
    }
}
