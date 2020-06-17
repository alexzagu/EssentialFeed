//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 17/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import XCTest

class URLSessionHTTPClient {

    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL) {
        self.session.dataTask(with: url) { _, _, _ in }
    }

}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url)

        XCTAssertEqual(session.receivedURLs, [url])
    }

    // MARK: - Helpers

    private class URLSessionSpy: URLSession {

        var receivedURLs = [URL]()

        override func dataTask(with url: URL,
                               completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            self.receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }

    }

    private class FakeURLSessionDataTask: URLSessionDataTask {}

}
