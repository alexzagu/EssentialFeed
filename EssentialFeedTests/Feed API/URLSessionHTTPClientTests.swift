//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 17/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import EssentialFeed
import XCTest

class URLSessionHTTPClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        self.session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }

}

class URLSessionHTTPClientTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDownWithError() throws {
        URLProtocolStub.stopInterceptingRequests()
        try super.tearDownWithError()
    }

    func test_getFromURL_performsGETRequestWithURL() {
        let url = self.anyURL()
        let expectation = self.expectation(description: "Wait for request.")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }

        self.makeSUT().get(from: url) { _ in }

        self.wait(for: [expectation], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {
        let requestError = NSError(domain: "any-error", code: 0)

        let receivedError = self.resultErrorFor(data: nil, response: nil, error: requestError)

        XCTAssertEqual(receivedError as NSError?, requestError)
    }

    func test_getFromURL_failsOnAllNilValues() {
        XCTAssertNotNil(self.resultErrorFor(data: nil, response: nil, error: nil))
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        self.trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func anyURL() -> URL { URL(string: "https://any-url.com")! }

    private func resultErrorFor(data: Data?,
                                response: URLResponse?,
                                error: Error?,
                                file: StaticString = #file,
                                line: UInt = #line) -> Error? {

        URLProtocolStub.stub(data: data, response: response, error: error)

        let sut = self.makeSUT(file: file, line: line)
        let expectation = self.expectation(description: "Wait for completion.")
        var receivedError: Error?

        sut.get(from: self.anyURL()) { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure, but got \(result) instead.", file: file, line: line)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1.0)

        return receivedError
    }

    private class URLProtocolStub: URLProtocol {

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        private static var stub: Stub?

        private static var requestObserver: ((URLRequest) -> Void)?

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            self.stub = Stub(data: data, response: response, error: error)
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            self.requestObserver = observer
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            self.stub = nil
            self.requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            self.requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            if let data = Self.stub?.data {
                self.client?.urlProtocol(self, didLoad: data)
            }

            if let response = Self.stub?.response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = Self.stub?.error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }

            self.client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

    }

}
