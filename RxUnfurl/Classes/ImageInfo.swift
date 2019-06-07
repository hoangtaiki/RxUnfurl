//
//  ImageInfo.swift
//  RxUnfurl
//
//  Created by Harry Tran on 6/7/19.
//

import UIKit

public struct ImageInfo {
    
    public let url: URL
    public let size: CGSize
    
    public var debugDescription: String {
        return "ImageInfo{url='\(url.absoluteString)', size.width=\(size.width)size.height\(size.height)"
    }
    
    public init(url: URL, size: CGSize) {
        self.url = url
        self.size = size
    }
}
