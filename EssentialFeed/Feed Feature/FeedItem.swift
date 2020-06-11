//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 10/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public struct FeedItem: Equatable {

    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL

}
