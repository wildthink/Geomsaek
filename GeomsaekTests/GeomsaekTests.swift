//
//  GeomsaekTests.swift
//  GeomsaekTests
//
//  Copyright © 2015 Nate Cook. All rights reserved.
//

import XCTest
@testable import Geomsaek

class GeomsaekTests: XCTestCase {
    
    lazy var index: Index = Index()
    
    lazy var searcher: Searcher = {
        Searcher(inIndex: self.index)
    }()

    func fillIndex(_ index: Index) {
        // Thank you, Project Gutenberg
        let path = Bundle(for: GeomsaekTests.self).resourcePath!
        for i in 10...39 {
            let filePath = "\(path)/\(i).txt"
            let contents = try! String(contentsOfFile: filePath)
            index.add(Document(url: URL(fileURLWithPath: filePath)), withText: contents)
        }
        index.flushIndex()
    }
    
    func testFillCount() {
        XCTAssertEqual(index.documentCount, 0)
        fillIndex(index)
        XCTAssertGreaterThanOrEqual(index.documentCount, 30)
    }
    
    func testSearch() {
        fillIndex(index)
        
        let terms = ["hackers": 1, "first": 28, "elephant*": 2, "zcxjvnalskjdnf": 0]
        let expectation = self.expectation(description: "Searching")
        
        var searches = 0
        terms.forEach { (term, expectedCount) in
            searches += 1
            searcher.startSearch(term) { results in
                XCTAssertEqual(results.documents.count, expectedCount)
                searches -= 1
                if searches == 0 {
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 500, handler: nil)
    }
}
