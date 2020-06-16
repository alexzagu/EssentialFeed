//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 11/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader {

    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public typealias Result = Swift.Result<[FeedItem], Error>

    public func load(completion: @escaping (Result) -> Void) {
        self.client.get(from: self.url) { result in
            switch result {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }

}
