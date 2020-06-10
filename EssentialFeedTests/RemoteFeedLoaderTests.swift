//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import XCTest

class RemoteFeedLoader {

    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func load() {
        self.client.get(from: URL(string: "https://a-url.com")!)
    }

}

protocol HTTPClient {

    func get(from url: URL)

}

class HTTPClientSpy: HTTPClient {

    var requestedURL: URL?

    func get(from url: URL) {
        self.requestedURL = url
    }

}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestsDataFromURL() {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }

}
