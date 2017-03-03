//
//  Document.swift
//  Geomsaek
//
//  Copyright © 2015 Nate Cook. All rights reserved.
//

import Foundation

public typealias DocumentID = SKDocumentID

public struct Document {
    internal let _doc: SKDocument

    public var url: URL {
        return SKDocumentCopyURL(_doc).takeRetainedValue() as URL
    }

    public init(url: URL) {
        self._doc = SKDocumentCreateWithURL(url as CFURL).takeRetainedValue()
    }
    
    internal init(_skdoc: SKDocument) {
        self._doc = _skdoc
    }
}

