//
//  Index.swift
//  Geomsaek
//
//  Copyright © 2015 Nate Cook. All rights reserved.
//

import Foundation

public enum IndexType: Int {
    case unknown         = 0
    case inverted        = 1
    case vector          = 2
    case invertedVector  = 3
   
    fileprivate var _skIndexType: SKIndexType {
        return SKIndexType(rawValue: UInt32(self.rawValue))
    }
}

open class Index {
    internal let _index: SKIndex
    
    public init(name: String? = nil, type: IndexType = .inverted, properties: [AnyHashable: Any] = [:]) {
        let mutableData = NSMutableData()
        self._index = SKIndexCreateWithMutableData(mutableData, name as CFString!, type._skIndexType, properties as CFDictionary!).takeRetainedValue()
    }
    
    public init(mutableData: NSMutableData, name: String? = nil, type: IndexType = .inverted, properties: [AnyHashable: Any] = [:]) {
        if let index = SKIndexOpenWithMutableData(mutableData, name as CFString!) {
            self._index = index.takeRetainedValue()
        } else {
            self._index = SKIndexCreateWithMutableData(mutableData, name as CFString!, type._skIndexType, properties as CFDictionary!).takeRetainedValue()
        }
    }
    
    public init(url: URL, name: String? = nil, type: IndexType = .inverted, properties: [AnyHashable: Any] = [:]) {
        if let index = SKIndexOpenWithURL(url as CFURL!, name as CFString!, true) {
            self._index = index.takeRetainedValue()
        } else {
            self._index = SKIndexCreateWithURL(url as CFURL!, name as CFString!, type._skIndexType, properties as CFDictionary!).takeRetainedValue()
        }
    }
    
    open func add(_ document: Document, withText text: String, replacing: Bool = true) {
        SKIndexAddDocumentWithText(_index, document._doc, text as CFString!, replacing)
    }
    
    open func add(_ document: Document, withMimeHint hint: String? = nil, replacing: Bool = true) {
        SKIndexAddDocument(_index, document._doc, hint as CFString!, replacing)
    }
    
    open func flushIndex() {
        SKIndexFlush(_index)
    }
    
    internal func documentsWithIDs(_ documentIDs: inout [DocumentID]) -> [Document?] {
        var unmanagedDocuments: [Unmanaged<SKDocument>?] = Array(repeating: nil, count: documentIDs.count)
        
        SKIndexCopyDocumentRefsForDocumentIDs(_index, documentIDs.count, &documentIDs, &unmanagedDocuments)
        return unmanagedDocuments.map({
            guard let skdoc = $0?.takeRetainedValue() else { return nil }
//            return Document(url: (skdoc as! NSURL) as URL)
            return Document(url: skdoc)
        })
    }
    
    internal func urlsWithIDs(_ documentIDs: inout [DocumentID]) -> [URL?] {
        // unmanagedURLs will get populated with CFURL objects from the array of document IDs
        var unmanagedURLs: [Unmanaged<CFURL>?] = Array(repeating: nil, count: documentIDs.count)
        SKIndexCopyDocumentURLsForDocumentIDs(_index, documentIDs.count, &documentIDs, &unmanagedURLs)
        
        // take the retained value of each url, then convert from CFURL? to NSURL?
        return unmanagedURLs.map({ $0?.takeRetainedValue() as URL? })
    }
    
    open var documentCount: Int {
        return SKIndexGetDocumentCount(_index)
    }
}

