//
//  PreviewData.swift
//  RxUnfurl
//
//  Created by Harry Tran on 6/7/19.
//

import UIKit

public struct PreviewData {
    
    public var url: URL?
    public var title: String = ""
    public var description: String = ""
    public var images: [ImageInfo] = []
    
    public var debugDescription: String {
        return "PreviewData{url='\(url?.absoluteString ?? "")', title=\(title), description=\(description), images=\(images)"
    }
    
    public init(url: URL? = nil, title: String = "", description: String = "", images: [ImageInfo] = []) {
        self.url = url
        self.title = title
        self.description = description
        self.images = images
    }
}

