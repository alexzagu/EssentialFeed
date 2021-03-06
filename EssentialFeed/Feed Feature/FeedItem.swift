//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public struct FeedItem: Equatable {

    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL

    public init(id: UUID,
                description: String? = nil,
                location: String? = nil,
                imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }

}
