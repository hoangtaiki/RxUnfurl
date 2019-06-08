//
//  RxUnfurl.swift
//  Alamofire
//
//  Created by Harry Tran on 6/7/19.
//

import RxSwift

public class RxUnfurl {
    
    private var urlSession: URLSession
    private let imageSizeFetcher = ImageSizeFetcher()

    public init(urlSession: URLSession = URLSession(configuration: .ephemeral)) {
        self.urlSession = urlSession
    }
    
    public func generatePreviewFromURL(_ url: URL) -> Single<PreviewData> {
        return getPreViewAndImageURL(url)
            .flatMap { [unowned self] (tuple) -> Single<PreviewData> in
                guard let imageURL = tuple.1 else {
                    return Single.just(tuple.0)
                }

            return Single.zip(Single.just(tuple.0), self.extractImageSize(url: imageURL))
                .map({ (tuple) -> PreviewData in
                    var previewData = tuple.0
                    previewData.image = tuple.1
                    return previewData
            })
        }
    }
    
    private func getPreViewAndImageURL(_ url: URL) -> Single<(PreviewData, URL?)> {
        return Single<(PreviewData, URL?)>.create { single in
            let task = self.urlSession.dataTask(with: url) { (data, response, error) in
                if let networkError = error {
                    single(.error(networkError))
                }
                
                if let contentType = (response as? HTTPURLResponse)?.allHeaderFields["Content-Type"] as? String {
                    var previewData = PreviewData(url: url)
                    var imageURL: URL?
                    
                    if contentType.hasPrefix("image") {
                        imageURL = url
                    } else if contentType.hasPrefix("text/html") {
                        guard let htmlString = String(data: data!, encoding: String.Encoding.utf8) else {
                            single(.error(RxUnfurlError.encodingError))
                            return
                        }
                        
                        let attributes = self.parse(htmlString: htmlString)
                        if let title = attributes[.title] {
                            previewData.title = title
                        }
                        
                        if let description = attributes[.description] {
                            previewData.description = description
                        }
                        
                        if let image = attributes[.image] {
                            imageURL = URL(string: image)
                        }
                    }
                    
                    single(.success((previewData, imageURL)))
                    
                } else {
                    single(.error(RxUnfurlError.noContentType))
                }
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    
    private func extractImageSize(url: URL) -> Single<ImageInfo> {
        return Single<ImageInfo>.create { single in
            let task = self.urlSession.dataTask(with: url) { (data, response, error) in
                if let networkError = error {
                    single(.error(networkError))
                }
                
                if let responseData = data {
                    do {
                        if let imageSize = try self.imageSizeFetcher.imageSize(data: responseData) {
                            single(.success(ImageInfo(url: url, size: imageSize)))
                        }
                    } catch {
                        single(.error(error))
                    }
                }
                
                single(.error(RxUnfurlError.unexpectedError))
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    
    private func parse(htmlString: String) -> [Metadata: String] {
        // extract meta tag
        let metatagRegex  = try! NSRegularExpression(
            pattern: "<meta(?:\".*?\"|\'.*?\'|[^\'\"])*?>",
            options: [.dotMatchesLineSeparators]
        )
        let metaTagMatches = metatagRegex.matches(in: htmlString,
                                                  options: [],
                                                  range: NSMakeRange(0, htmlString.count))
        if metaTagMatches.isEmpty {
            return [:]
        }
        
        // prepare regular expressions to extract og property and content.
        let propertyRegexp = try! NSRegularExpression(
            pattern: "\\sproperty=(?:\"|\')og:([a-zA_Z:]+?)(?:\"|\')",
            options: []
        )
        let contentRegexp = try! NSRegularExpression(
            pattern: "\\scontent=\"(.*?)\"",
            options: []
        )
        
        // create attribute dictionary
        let nsString = htmlString as NSString
        let attributes = metaTagMatches.reduce([Metadata: String]()) { (attributes, result) -> [Metadata: String] in
            var copiedAttributes = attributes
            
            let property = { () -> (name: String, content: String)? in
                let metaTag = nsString.substring(with: result.range(at: 0))
                let propertyMatches = propertyRegexp.matches(in: metaTag,
                                                             options: [],
                                                             range: NSMakeRange(0, metaTag.count))
                guard let propertyResult = propertyMatches.first else { return nil }
                
                var contentMatches = contentRegexp.matches(in: metaTag, options: [], range: NSMakeRange(0, metaTag.count))
                if contentMatches.first == nil {
                    let contentRegexp = try! NSRegularExpression(
                        pattern: "\\scontent='(.*?)'",
                        options: []
                    )
                    contentMatches = contentRegexp.matches(in: metaTag, options: [], range: NSMakeRange(0, metaTag.count))
                }
                guard let contentResult = contentMatches.first else { return nil }
                
                let nsMetaTag = metaTag as NSString
                let property = nsMetaTag.substring(with: propertyResult.range(at: 1))
                let content = nsMetaTag.substring(with: contentResult.range(at: 1))
                
                return (name: property, content: content)
            }()
            if let property = property, let metadata = Metadata(rawValue: property.name) {
                copiedAttributes[metadata] = property.content
            }
            return copiedAttributes
        }
        
        return attributes
    }
}
