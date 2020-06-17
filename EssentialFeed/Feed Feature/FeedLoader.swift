//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public protocol FeedLoader {

    typealias Result = Swift.Result<[FeedItem], Error>
    func load(completion: @escaping (Result) -> Void)

}
