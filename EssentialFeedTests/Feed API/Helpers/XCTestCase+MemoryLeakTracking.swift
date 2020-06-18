//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Alejandro Zamudio Guajardo on 19/06/2020.
//  Copyright © 2020 MWare. All rights reserved.
//

import XCTest

extension XCTestCase {

    internal func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        self.addTeardownBlock { [weak instance] in
            XCTAssertNil(instance,
                         "Instance should have been deallocated. Potential memory leak.",
                         file: file,
                         line: line)
        }
    }

}
