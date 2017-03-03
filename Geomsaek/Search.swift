//
//  Search.swift
//  Geomsaek
//
//  Copyright © 2015 Nate Cook. All rights reserved.
//

import Foundation

public enum SearchOptions: UInt32 {
   case `default`             = 0b000
   case noRelevanceScores   = 0b001
   case spaceMeansOR        = 0b010
   case findSimilar         = 0b100
}

private let _searchQueue = OperationQueue()

private class _SearchOperation: Operation {
    let search: SKSearch
    var results: [DocumentID] = []
    var resultScores: [Float] = []
    var shouldCancel = false
    var progressBlock: (([SKDocumentID], [Float]) -> Void)?
    
    override func main() {
        super.main()
        
        var moreResults = true
        let limit = 20
        
        while moreResults && !shouldCancel {
            var found: CFIndex = 0
            var documentIDs: [SKDocumentID] = Array(repeating: 0, count: limit)
            var scores: [Float] = Array(repeating: 0, count: limit)
            
            moreResults = SKSearchFindMatches(search, limit, &documentIDs, &scores, 1000, &found)
            
            // append only the found results
            results.append(contentsOf: documentIDs[0 ..< found])
            resultScores.append(contentsOf: scores[0 ..< found])
            
            // call progress block
            progressBlock?(results, resultScores)
        }
    }
    
    init(search: SKSearch) {
        self.search = search
    }
}

open class Searcher {
    public typealias SearchID = Int
    public typealias SearchResultsHandler = (SearchResults) -> Void

    fileprivate let _index: Index
    fileprivate let _options: SKSearchOptions

    fileprivate var _nextSearchID = 0
    fileprivate var _searches: [SearchID: _SearchOperation] = [:]
    
    public init(inIndex index: Index, options: SearchOptions = .default) {
        self._index = index
        self._options = options.rawValue
    }
    
    open func startSearch(_ terms: String, progressHandler: SearchResultsHandler? = nil, completionHandler: SearchResultsHandler?) -> SearchID {
        // create a search and a new unique search ID
        let search = SKSearchCreate(_index._index, terms as CFString!, _options).takeRetainedValue()
        _nextSearchID += 1
        let searchID = _nextSearchID

        // create a search operation to run the search on the `searchQueue` operations queue
        let searchOperation = _SearchOperation(search: search)
        
        // we only need to add a progress handler to the operation if we have one to call
        if let progressHandler = progressHandler {
            searchOperation.progressBlock = { resultsBatch, scoresBatch in
                let results = SearchResults(index: self._index, documentIDs: resultsBatch, scores: scoresBatch)
                progressHandler(results)
            }
        }
        
        // but we need the completion block either way, since it clears the operation and 
        // consquently the SKSearchRef object from the dictionary
        searchOperation.completionBlock = {
            if let completionHandler = completionHandler {
                let results = SearchResults(index: self._index, documentIDs: searchOperation.results, scores: searchOperation.resultScores)
                completionHandler(results)
            }
            self._searches[searchID] = nil
        }

        // save the operation in our dictionary so we can cancel it using the search ID,
        // then add it to the search queue to kick off returning the results
        _searches[searchID] = searchOperation
        _searchQueue.addOperation(searchOperation)

        return searchID
    }
    
    open func cancelSearch(_ searchID: SearchID) {
        if let operation = _searches[searchID] {
            operation.shouldCancel = true
            SKSearchCancel(operation.search)
        }
    }
    
    open func cancelAllSearches() {
        _searches.keys.forEach(cancelSearch)
    }
}

open class SearchResults {
    internal let _index: Index
    open var documentIDs: [DocumentID]
    open let scores: [Float]
    
    internal var _documents: [Document]?
    open var documents: [Document] {
        if _documents == nil {
            _documents = _index.documentsWithIDs(&documentIDs).flatMap({ $0 })
        }
        return _documents!
    }
    
    internal var _urls: [URL]?
    open var urls: [URL] {
        if _urls == nil {
            _urls = _index.urlsWithIDs(&documentIDs).flatMap({ $0 })
        }
        return _urls!
    }
    
    init(index: Index, documentIDs: [DocumentID], scores: [Float]) {
        self._index = index
        self.documentIDs = documentIDs
        self.scores = scores
    }
}

