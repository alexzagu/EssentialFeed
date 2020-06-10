//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import XCTest

class RemoteFeedLoader {

    func load() {
        HTTPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }

}

class HTTPClient {

    static var shared = HTTPClient()

    func get(from url: URL) {}

}

class HTTPClientSpy: HTTPClient {

    var requestedURL: URL?

    override func get(from url: URL) {
        self.requestedURL = url
    }

}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        _ = RemoteFeedLoader()

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestsDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = RemoteFeedLoader()

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }

}
