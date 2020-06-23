//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 17/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import EssentialFeed
import XCTest

class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        self.session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
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
        let requestError = self.anyNSError()

        let receivedError = self.resultErrorFor(data: nil, response: nil, error: requestError)

        XCTAssertEqual(receivedError as NSError?, requestError)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(self.resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(self.resultErrorFor(data: nil, response: self.nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(self.resultErrorFor(data: self.anyData(), response: nil, error: nil))
        XCTAssertNotNil(self.resultErrorFor(data: self.anyData(), response: nil, error: self.anyNSError()))
        XCTAssertNotNil(self.resultErrorFor(data: nil, response: self.nonHTTPURLResponse(), error: self.anyNSError()))
        XCTAssertNotNil(self.resultErrorFor(data: nil, response: self.anyHTTPURLResponse(), error: self.anyNSError()))
        XCTAssertNotNil(self.resultErrorFor(data: self.anyData(), response: self.nonHTTPURLResponse(), error: self.anyNSError()))
        XCTAssertNotNil(self.resultErrorFor(data: self.anyData(), response: self.anyHTTPURLResponse(), error: self.anyNSError()))
        XCTAssertNotNil(self.resultErrorFor(data: self.anyData(), response: self.nonHTTPURLResponse(), error: nil))
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = self.anyData()
        let response = self.anyHTTPURLResponse()

        let receivedValues = self.resultValuesFor(data: data, response: response, error: nil)

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = self.anyHTTPURLResponse()

        let receivedValues = self.resultValuesFor(data: nil, response: response, error: nil)

        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        self.trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func anyURL() -> URL { URL(string: "https://any-url.com")! }

    private func anyData() -> Data { Data("any data".utf8) }

    private func anyNSError() -> NSError { NSError(domain: "any error", code: 0) }

    private func anyHTTPURLResponse() -> HTTPURLResponse { HTTPURLResponse(url: self.anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)! }

    private func nonHTTPURLResponse() -> URLResponse { URLResponse(url: self.anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }

    private func resultValuesFor(data: Data?,
                                 response: URLResponse?,
                                 error: Error?,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {

        let result = self.resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .success(values):
            return values
        default:
            XCTFail("Expected success, but got \(result) instead.", file: file, line: line)
            return nil
        }
    }

    private func resultErrorFor(data: Data?,
                                response: URLResponse?,
                                error: Error?,
                                file: StaticString = #file,
                                line: UInt = #line) -> Error? {

        let result = self.resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, but got \(result) instead.", file: file, line: line)
            return nil
        }
    }

    private func resultFor(data: Data?,
                           response: URLResponse?,
                           error: Error?,
                           file: StaticString = #file,
                           line: UInt = #line) -> HTTPClient.Result {

        URLProtocolStub.stub(data: data, response: response, error: error)

        let sut = self.makeSUT(file: file, line: line)
        let expectation = self.expectation(description: "Wait for completion.")
        var receivedResult: HTTPClient.Result!

        sut.get(from: self.anyURL()) { result in
            receivedResult = result
            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1.0)

        return receivedResult
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
