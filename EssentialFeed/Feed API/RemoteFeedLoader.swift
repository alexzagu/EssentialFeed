//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 11/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {

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

    public typealias Result = FeedLoader.Result

    public func load(completion: @escaping (Result) -> Void) {
        self.client.get(from: self.url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

}
