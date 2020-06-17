//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 17/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import EssentialFeed
import XCTest

protocol HTTPSession {
    func dataTask(with url: URL,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {

    private let session: HTTPSession

    init(session: HTTPSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        self.session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }

}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let task = HTTPSessionTaskSpy()
        session.stub(url: url, task: task)

        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url) { _ in }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "any-error", code: 0)
        session.stub(url: url, error: error)

        let sut = URLSessionHTTPClient(session: session)

        let expectation = self.expectation(description: "Wait for completion.")

        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error \(error), but got \(result) instead.")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private class HTTPSessionSpy: HTTPSession {

        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }

        private var stubs = [URL: Stub]()

        func stub(url: URL, task: HTTPSessionTask = FakeHTTPSessionTask(), error: Error? = nil) {
            self.stubs[url] = Stub(task: task, error: error)
        }

        func dataTask(with url: URL,
                      completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = self.stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }

            completionHandler(nil, nil, stub.error)
            return stub.task
        }

    }

    private class FakeHTTPSessionTask: HTTPSessionTask {
        func resume() {}
    }

    private class HTTPSessionTaskSpy: HTTPSessionTask {

        var resumeCallCount = 0

        func resume() {
            self.resumeCallCount += 1
        }

    }

}
