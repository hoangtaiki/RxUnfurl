//
//  PreviewData.swift
//  RxUnfurl
//
//  Created by Harry Tran on 6/7/19.
//

import UIKit

public struct PreviewData {
    
    public var url: URL
    public var title: String = ""
    public var description: String = ""
    public var image: ImageInfo?
    
    public var debugDescription: String {
        return "PreviewData{url='\(url.absoluteString)', title=\(title), description=\(description), images=\(String(describing: image))"
    }
    
    public init(url: URL, title: String = "", description: String = "", image: ImageInfo? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.image = image
    }
}

