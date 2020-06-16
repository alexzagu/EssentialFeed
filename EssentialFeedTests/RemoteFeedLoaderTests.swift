//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import EssentialFeed
import XCTest

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = self.makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = self.makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = self.makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = self.makeSUT()

        self.expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = self.makeSUT()

        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            self.expect(sut, toCompleteWith: .failure(.invalidData), when: {
                let json = self.makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }

    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = self.makeSUT()

        self.expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = self.makeSUT()

        self.expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = self.makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = self.makeSUT()

        let item1 = self.makeItem(id: UUID(),
                                  imageURL: URL(string: "https://a-url.com")!)

        let item2 = self.makeItem(id: UUID(),
                                  description: "a description",
                                  location: "a location",
                                  imageURL: URL(string: "https://another-url.com")!)

        let items = [item1.model, item2.model]

        self.expect(sut, toCompleteWith: .success(items), when: {
            let json = self.makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {

        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        self.trackForMemoryLeaks(sut, file: file, line: line)
        self.trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        self.addTeardownBlock { [weak instance] in
            XCTAssertNil(instance,
                         "Instance should have been deallocated. Potential memory leak.",
                         file: file,
                         line: line)
        }
    }

    private func makeItem(id: UUID,
                          description: String? = nil,
                          location: String? = nil,
                          imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id,
                            description: description,
                            location: location,
                            imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith result: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {

        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }

        action()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {

        private var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()

        var requestedURLs: [URL] {
            self.messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            self.messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            self.messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: self.requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!

            self.messages[index].completion(.success((data, response)))
        }

    }

}
