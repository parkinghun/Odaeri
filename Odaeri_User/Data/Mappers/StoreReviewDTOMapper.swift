//
//  StoreReviewDTOMapper.swift
//  Odaeri_User
//
//  Created by 박성훈 on 3/1/26.
//

import Foundation

enum StoreReviewDTOMapper {
    static func toEntity(_ dto: StoreRevewItemDTO) -> StoreReviewEntity {
        StoreReviewEntity(
            reviewId: dto.reviewId,
            content: dto.content,
            rating: dto.rating,
            reviewImageUrls: dto.reviewImageUrls,
            orderMenuList: dto.orderMenuList,
            creator: StoreDTOMapper.toEntity(dto.creator),
            userTotalReviewCount: dto.userTotalReviewCount,
            userTotalRating: dto.userTotalRating,
            createdAt: dto.createdAt.toDate(),
            updatedAt: dto.updatedAt.toDate()
        )
    }

    static func toEntity(_ dto: StoreReviewResponse) -> StoreReviewDetailEntity {
        StoreReviewDetailEntity(
            reviewId: dto.reviewID,
            content: dto.content,
            rating: dto.rating,
            store: StoreDTOMapper.toEntity(dto.store),
            reviewImageUrls: dto.reviewImageUrls,
            orderMenuList: dto.orderMenuList,
            creator: StoreDTOMapper.toEntity(dto.creator),
            createdAt: dto.createdAt.toDate(),
            updatedAt: dto.updatedAt.toDate()
        )
    }

    static func toEntity(_ dto: RatingData) -> ReviewRatingEntity {
        ReviewRatingEntity(
            rating: dto.rating,
            count: dto.count
        )
    }
}
