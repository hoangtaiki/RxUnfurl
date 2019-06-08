//
//  ImageDecoder.swift
//  RxUnfurl
//
//  Created by Harry Tran on 6/7/19.
//

import UIKit

/// Errors generated by the parser.
///
/// - unsupportedFormat: unsupported image format.
public enum RxUnfurlError: Error {
    case unsupportedFormat
    case networkError(Error)
    case noContentType
    case encodingError
    case unexpectedError
}

/// Parser is the main core class which parse collected partial data and attempts
/// to get the image format along with the size of the frame.
public class ImageSizeFetcher {
    
    /// Supported image formats
    public enum Format {
        case jpeg, png, gif, bmp
        
        /// Minimum amount of data (in bytes) required to parse successfully the frame size.
        /// When `nil` it means the format has a variable data length and therefore
        /// a parsing operation is always required.
        var minimumSample: Int? {
            switch self {
            case .jpeg:
                return nil // will be checked by the parser (variable data is required)
            case .png:
                return 25
            case .gif:
                return 11
            case .bmp:
                return 29
            }
        }
        
        /// Attempt to recognize a known signature from collected partial data.
        ///
        /// - Parameter data: partial data from server.
        /// - Throws: throw an exception if file is not supported.
        internal init(fromData data: Data) throws {
            // Evaluate the format of the image
            let length: UInt16 = data[0..<2]
            switch CFSwapInt16(length) {
            case 0xFFD8:
                self = .jpeg
            case 0x8950:
                self = .png
            case 0x4749:
                self = .gif
            case 0x424D:
                self = .bmp
            default:
                throw RxUnfurlError.unsupportedFormat
            }
        }
    }
    
    /// Parse collected data from a specified file format and attempt to get the size of the image frame.
    ///
    /// - Parameters:
    ///   - format: format of the data.
    ///   - data: collected data.
    /// - Returns: size of the image, `nil` if cannot be evaluated with collected data.
    /// - Throws: throw an exception if parser fail or data is corrupted.
    func imageSize(data: Data) throws -> CGSize? {
        let format = try ImageSizeFetcher.Format(fromData: data) // attempt to parse signature
        if let minLen = format.minimumSample, data.count <= minLen {
            return nil // not enough data collected to evaluate png size
        }
        
        switch format {
        case .bmp:
            let length: UInt16 = data[14, 4]
            let start = 18
            let startOffset = length == 12 ? 4 : 2
            let width: UInt32 = data[start, startOffset]
            let height: UInt32 = data[start, startOffset]
            
            return CGSize(width: Int(width), height: Int(height))
            
        case .png:
            let width: UInt32 = data[16, 4]
            let height: UInt32 = data[20, 4]
            
            return CGSize(width: Int(CFSwapInt32(width)), height: Int(CFSwapInt32(height)))
            
        case .gif:
            let width: UInt16 = data[6, 2]
            let height: UInt16 = data[8, 2]
            
            return CGSize(width: Int(width), height: Int(height))
            
        case .jpeg:
            var i: Int = 0
            // check for valid JPEG image
            // http://www.fastgraph.com/help/jpeg_header_format.html
            guard data[i] == 0xFF && data[i+1] == 0xD8 && data[i+2] == 0xFF && data[i+3] == 0xE0 else {
                throw RxUnfurlError.unsupportedFormat // Not a valid SOI header
            }
            i += 4
            
            // Check for valid JPEG header (null terminated JFIF)
            guard data[i+2].char == "J" && data[i+3].char == "F"
                && data[i+4].char == "I" && data[i+5].char == "F" && data[i+6] == 0x00 else {
                    throw RxUnfurlError.unsupportedFormat // Not a valid JFIF string
            }
            
            // Retrieve the block length of the first block since the
            // first block will not contain the size of file
            var blockLength: UInt16 = UInt16(data[i]) * 256 + UInt16(data[i+1])
            repeat {
                i += Int(blockLength) // Increase the file index to get to the next block
                if i >= data.count { // Check to protect against segmentation faults
                    return nil
                }
                if data[i] != 0xFF { //Check that we are truly at the start of another block
                    return nil
                }
                if data[i+1] >= 0xC0 && data[i+1] <= 0xC3 { // if marker type is SOF0, SOF1, SOF2
                    // "Start of frame" marker which contains the file size
                    let h: UInt16 = data[i + 5, 2]
                    let w: UInt16 = data[i + 7, 2]
                    
                    let size = CGSize(width: Int(CFSwapInt16(w)), height: Int(CFSwapInt16(h)) );
                    return size
                } else {
                    // Skip the block marker
                    i+=2;
                    blockLength = UInt16(data[i]) * 256 + UInt16(data[i+1]);   // Go to the next block
                }
            } while (i < data.count)
            
            return nil
        }
    }
}

// MARK: Private Foundation Extensions

private extension Data {
    
    subscript<T>(start: Int, length: Int) -> T {
        return self[start..<start + length]
    }
    
    subscript<T>(range: Range<Data.Index>) -> T {
        return subdata(in: range).withUnsafeBytes { $0.load(as: T.self) }
    }
}

private extension UInt8 {
    
    /// Convert to char
    var char: Character {
        return Character(UnicodeScalar(self))
    }
}
