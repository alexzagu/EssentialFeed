//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 11/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public protocol HTTPClient {

    typealias Result = Swift.Result<HTTPURLResponse, Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)

}

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

    public func load(completion: @escaping (Error) -> Void) {
        self.client.get(from: self.url) { result in
            switch result {
            case .success:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
        }
    }

}
