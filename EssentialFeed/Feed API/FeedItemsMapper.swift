//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 16/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

internal final class FeedItemsMapper {

    private struct Root: Decodable {
        let items: [Item]

        var feed: [FeedItem] {
            self.items.map { $0.item }
        }
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            FeedItem(id: self.id,
                     description: self.description,
                     location: self.location,
                     imageURL: self.image)
        }
    }

    internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == 200,
            let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
        }

        return .success(root.feed)
    }

}
