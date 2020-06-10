//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

protocol FeedLoader {

    typealias LoadFeedResult = Result<[FeedItem], Error>
    func load(completion: @escaping (LoadFeedResult) -> Void)

}
