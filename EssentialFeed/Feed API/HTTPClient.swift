//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Alejandro Zamudio Guajardo on 16/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import Foundation

public protocol HTTPClient {

    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)

}
