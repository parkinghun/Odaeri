//
//  AdminOrderMockFactory.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation

enum AdminOrderMockFactory {
    static func makeOrders() -> [OrderListItemEntity] {
        let store = makeStoreEntity()
        let latte = makeMenuEntity(
            id: "menu_1",
            category: "커피",
            name: "카페 라떼",
            description: "부드러운 라떼",
            originInformation: "원두: 에티오피아",
            price: 4800,
            tags: ["HOT"]
        )

        let cheesecake = makeMenuEntity(
            id: "menu_2",
            category: "디저트",
            name: "치즈케이크",
            description: "진한 치즈케이크",
            originInformation: "국산 치즈",
            price: 5500,
            tags: ["BEST"]
        )

        let sandwich = makeMenuEntity(
            id: "menu_3",
            category: "베이커리",
            name: "클럽 샌드위치",
            description: "바삭한 베이컨 샌드위치",
            originInformation: "베이컨: 국내산",
            price: 7200,
            tags: ["NEW"]
        )

        let tea = makeMenuEntity(
            id: "menu_4",
            category: "티",
            name: "얼그레이 티",
            description: "향긋한 얼그레이",
            originInformation: "찻잎: 인도산",
            price: 4200,
            tags: ["ICE"]
        )

        var orders: [OrderListItemEntity] = []

        orders.append(makeOrder(
            id: "order_101",
            code: "A-1001",
            status: .pendingApproval,
            createdAt: Date().addingTimeInterval(MockValue.newOrderOffsets[0]),
            store: store,
            menus: [
                makeMenuItemEntity(menu: latte, quantity: 2),
                makeMenuItemEntity(menu: sandwich, quantity: 1)
            ]
        ))

        orders.append(makeOrder(
            id: "order_102",
            code: "A-1002",
            status: .pendingApproval,
            createdAt: Date().addingTimeInterval(MockValue.newOrderOffsets[1]),
            store: store,
            menus: [
                makeMenuItemEntity(menu: cheesecake, quantity: 1),
                makeMenuItemEntity(menu: tea, quantity: 2)
            ]
        ))

        orders.append(makeOrder(
            id: "order_201",
            code: "B-2001",
            status: .approved,
            createdAt: Date().addingTimeInterval(MockValue.activeOrderOffsets[0]),
            store: store,
            menus: [
                makeMenuItemEntity(menu: latte, quantity: 1),
                makeMenuItemEntity(menu: cheesecake, quantity: 1),
                makeMenuItemEntity(menu: tea, quantity: 1)
            ]
        ))

        orders.append(makeOrder(
            id: "order_202",
            code: "B-2002",
            status: .inProgress,
            createdAt: Date().addingTimeInterval(MockValue.activeOrderOffsets[1]),
            store: store,
            menus: [
                makeMenuItemEntity(menu: latte, quantity: 2),
                makeMenuItemEntity(menu: sandwich, quantity: 1)
            ]
        ))

        orders.append(makeOrder(
            id: "order_203",
            code: "B-2003",
            status: .readyForPickup,
            createdAt: Date().addingTimeInterval(MockValue.activeOrderOffsets[2]),
            store: store,
            menus: [
                makeMenuItemEntity(menu: cheesecake, quantity: 2),
                makeMenuItemEntity(menu: tea, quantity: 1)
            ]
        ))

        orders.append(makeOrder(
            id: "order_204",
            code: "B-2004",
            status: .inProgress,
            createdAt: Date().addingTimeInterval(MockValue.activeOrderOffsets[3]),
            store: store,
            menus: [
                makeMenuItemEntity(menu: latte, quantity: 1),
                makeMenuItemEntity(menu: sandwich, quantity: 1),
                makeMenuItemEntity(menu: tea, quantity: 1)
            ]
        ))

        orders.append(makeOrder(
            id: "order_301",
            code: "C-3001",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.completedOrderOffsets[0]),
            store: store,
            menus: [makeMenuItemEntity(menu: latte, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_302",
            code: "C-3002",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.completedOrderOffsets[1]),
            store: store,
            menus: [makeMenuItemEntity(menu: cheesecake, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_303",
            code: "C-3003",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.completedOrderOffsets[2]),
            store: store,
            menus: [makeMenuItemEntity(menu: latte, quantity: 2)]
        ))

        orders.append(makeOrder(
            id: "order_304",
            code: "C-3004",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.completedOrderOffsets[3]),
            store: store,
            menus: [makeMenuItemEntity(menu: cheesecake, quantity: 2)]
        ))

        orders.append(makeOrder(
            id: "order_305",
            code: "C-3005",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.completedOrderOffsets[4]),
            store: store,
            menus: [makeMenuItemEntity(menu: latte, quantity: 1), makeMenuItemEntity(menu: cheesecake, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_401",
            code: "D-4001",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[0]),
            store: store,
            menus: [makeMenuItemEntity(menu: latte, quantity: 1), makeMenuItemEntity(menu: tea, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_402",
            code: "D-4002",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[1]),
            store: store,
            menus: [makeMenuItemEntity(menu: cheesecake, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_403",
            code: "D-4003",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[2]),
            store: store,
            menus: [makeMenuItemEntity(menu: sandwich, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_404",
            code: "D-4004",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[3]),
            store: store,
            menus: [makeMenuItemEntity(menu: latte, quantity: 2)]
        ))

        orders.append(makeOrder(
            id: "order_405",
            code: "D-4005",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[4]),
            store: store,
            menus: [makeMenuItemEntity(menu: tea, quantity: 2)]
        ))

        orders.append(makeOrder(
            id: "order_406",
            code: "D-4006",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[5]),
            store: store,
            menus: [makeMenuItemEntity(menu: cheesecake, quantity: 2)]
        ))

        orders.append(makeOrder(
            id: "order_407",
            code: "D-4007",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[6]),
            store: store,
            menus: [makeMenuItemEntity(menu: latte, quantity: 1), makeMenuItemEntity(menu: sandwich, quantity: 1)]
        ))

        orders.append(makeOrder(
            id: "order_408",
            code: "D-4008",
            status: .pickedUp,
            createdAt: Date().addingTimeInterval(MockValue.salesOrderOffsets[7]),
            store: store,
            menus: [makeMenuItemEntity(menu: tea, quantity: 1), makeMenuItemEntity(menu: cheesecake, quantity: 1)]
        ))

        return orders
    }

    private static func makeOrder(
        id: String,
        code: String,
        status: OrderStatusEntity,
        createdAt: Date,
        store: OrderStoreInfoEntity,
        menus: [OrderMenuEntity]
    ) -> OrderListItemEntity {
        let totalPrice = menus.reduce(0) { $0 + $1.menu.price * $1.quantity }
        let dto = OrderListItem(
            orderId: id,
            orderCode: code,
            totalPrice: totalPrice,
            review: nil,
            store: makeStoreDTO(from: store),
            orderMenuList: menus.map { makeMenuDTO(from: $0) },
            currentOrderStatus: status.rawValue,
            orderStatusTimeline: [],
            paidAt: isoString(from: createdAt),
            createdAt: isoString(from: createdAt),
            updatedAt: isoString(from: createdAt)
        )
        return OrderListItemEntity(from: dto)
    }

    private static func makeStoreEntity() -> OrderStoreInfoEntity {
        let now = Date()
        let dto = OrderStoreInfo(
            id: "store_1",
            category: "카페",
            name: "오대리 카페",
            close: "22:00",
            storeImageUrls: [],
            hashTags: ["커피", "디저트"],
            geolocation: Geolocation(longitude: 127.1234, latitude: 37.1234),
            createdAt: isoString(from: now),
            updatedAt: isoString(from: now)
        )
        return OrderStoreInfoEntity(from: dto)
    }

    private static func makeMenuEntity(
        id: String,
        category: String,
        name: String,
        description: String,
        originInformation: String,
        price: Int,
        tags: [String]
    ) -> OrderMenuDetailEntity {
        let now = Date()
        let dto = OrderMenuDetail(
            id: id,
            category: category,
            name: name,
            description: description,
            originInformation: originInformation,
            price: price,
            tags: tags,
            menuImageUrl: "",
            createdAt: isoString(from: now),
            updatedAt: isoString(from: now)
        )
        return OrderMenuDetailEntity(from: dto)
    }

    private static func makeMenuItemEntity(menu: OrderMenuDetailEntity, quantity: Int) -> OrderMenuEntity {
        let dto = OrderMenuDTO(menu: makeMenuDTO(from: menu), quantity: quantity)
        return OrderMenuEntity(from: dto)
    }

    private static func makeMenuDTO(from entity: OrderMenuDetailEntity) -> OrderMenuDetail {
        OrderMenuDetail(
            id: entity.id,
            category: entity.category,
            name: entity.name,
            description: entity.description,
            originInformation: entity.originInformation,
            price: entity.price,
            tags: entity.tags,
            menuImageUrl: entity.menuImageUrl,
            createdAt: isoString(from: entity.createdAt ?? Date()),
            updatedAt: isoString(from: entity.updatedAt ?? Date())
        )
    }

    private static func makeMenuDTO(from entity: OrderMenuEntity) -> OrderMenuDTO {
        OrderMenuDTO(menu: makeMenuDTO(from: entity.menu), quantity: entity.quantity)
    }

    private static func makeStoreDTO(from entity: OrderStoreInfoEntity) -> OrderStoreInfo {
        OrderStoreInfo(
            id: entity.id,
            category: entity.category,
            name: entity.name,
            close: entity.close,
            storeImageUrls: entity.storeImageUrls,
            hashTags: entity.hashTags,
            geolocation: Geolocation(longitude: entity.longitude, latitude: entity.latitude),
            createdAt: isoString(from: entity.createdAt ?? Date()),
            updatedAt: isoString(from: entity.updatedAt ?? Date())
        )
    }

    private static func isoString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

private enum MockValue {
    static let newOrderOffsets: [TimeInterval] = [-300, -420]
    static let activeOrderOffsets: [TimeInterval] = [-900, -1200, -1500, -1800]
    static let completedOrderOffsets: [TimeInterval] = [-3600, -4200, -4800, -5400, -6000]
    static let salesOrderOffsets: [TimeInterval] = [
        -2 * 3600,
        -3 * 3600,
        -5 * 3600,
        -7 * 3600,
        -9 * 3600,
        -11 * 3600,
        -13 * 3600,
        -15 * 3600
    ]
}
