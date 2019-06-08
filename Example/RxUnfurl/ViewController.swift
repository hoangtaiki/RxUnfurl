//
//  ViewController.swift
//  RxUnfurl
//
//  Created by Harry Tran on 06/07/2019.
//  Copyright (c) 2019 Harry Tran. All rights reserved.
//

import UIKit
import RxSwift
import RxUnfurl

class ViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let prefetcher = ImageSizePrefetcher()
        let pngImageURL = URL(string: "https://i.imgur.com/vKYKUri.png")!
        prefetcher.getImageSizeFromURL(pngImageURL, imageType: .png) { (size, error) in
            guard let s = size else {
                return
            }
            print("PNG image size = \(s)")
        }

        let gifImageURL = URL(string: "https://www.w3.org/People/mimasa/test/imgformat/img/w3c_home.gif")!
        prefetcher.getImageSizeFromURL(gifImageURL, imageType: .gif) { (size, error) in
            guard let s = size else {
                return
            }
            print("GIF image size = \(s)")
        }
    }
}

enum PrefetcherImageType: Int {
    case jpeg, png, gif, bmp, unknown
}

class ImageSizePrefetcher {
    
    private var urlSession: URLSession
    
    public init(urlSession: URLSession = URLSession(configuration: .ephemeral)) {
        self.urlSession = urlSession
    }
    
    public func getImageSizeFromURL(_ url: URL, imageType: PrefetcherImageType? = nil,
                                    completion: @escaping ((CGSize?, Error?) -> Void)) {
        // If we specify image type
        if let type = imageType {
            switch type {
            case .png:
                getPNGImageSizeFromURL(url, completion: completion)
                return
            case .gif:
                getGIFImageSizeFromURL(url, completion: completion)
                return
            default:
                break
            }
        }
    }

    private func getPNGImageSizeFromURL(_ url: URL, completion: @escaping ((CGSize?, Error?) -> Void)) {
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("bytes=16-23", forHTTPHeaderField: "Range")
        getDataFromURLRequest(urlRequest) { (data, error) in
            if let data = data, data.count >= 8 {
                var width: UInt32 = 0
                var height: UInt32 = 0
                (data as NSData).getBytes(&width, range: NSMakeRange(0, 4))
                (data as NSData).getBytes(&height, range: NSMakeRange(4, 4))
                let imageSize = CGSize(width: Int(CFSwapInt32(width)), height: Int(CFSwapInt32(height)))
                
                completion(imageSize, nil)
            }
            
            completion(nil, error)
        }
    }
    
    private func getGIFImageSizeFromURL(_ url: URL, completion: @escaping ((CGSize?, Error?) -> Void)) {
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("bytes=6-9", forHTTPHeaderField: "Range")
        getDataFromURLRequest(urlRequest) { (data, error) in
            if let data = data, data.count == 4 {
                var width: UInt16 = 0
                var height: UInt16 = 0
                (data as NSData).getBytes(&width, range: NSMakeRange(0, 2))
                (data as NSData).getBytes(&height, range: NSMakeRange(2, 2))
                let imageSize = CGSize(width: Int(width), height: Int(height))
                
                completion(imageSize, nil)
            }
            completion(nil, error)
        }
    }
    
    private func getDataFromURLRequest(_ urlRequest: URLRequest, completion: @escaping ((Data?, Error?) -> Void)) {
        let task = urlSession.dataTask(with: urlRequest) { (data, _, error) in
            completion(data, error)
        }
        task.resume()
    }
    
    private func getImageTypeFromData(_ data: Data) -> PrefetcherImageType {
        if data.count < 2 {
            return .unknown
        }

        var word0: UInt8 = 0x0
        var word1: UInt8 = 0x0
        (data as NSData).getBytes(&word0, range: NSMakeRange(0, 1))
        (data as NSData).getBytes(&word1, range: NSMakeRange(1, 1))

        if word0 == 0xFF && word1 == 0xD8 {
            return .jpeg
        } else if word0 == 0x89 && word1 == 0x50 {
            return .png
        } else if word0 == 0x47 && word1 == 0x49 {
            return  .gif
        } else if word0 == 0x42 && word1 == 0x4D {
            return .bmp
        }
        
        return .unknown
    }
}

private extension UInt8 {
    
    var char: Character {
        return Character(UnicodeScalar(self))
    }
}
