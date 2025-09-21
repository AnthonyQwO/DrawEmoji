//
//  ExtensionFunctions.swift
//  DrawEmoji
//
//  Created by Tang Anthony on 2025/5/16.
//

import CoreVideo
import CoreImage
import UIKit

func convertToGrayScale(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }

    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceGray()

    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: width,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue),
          let cgGray = context.makeImage()
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    return UIImage(cgImage: context.makeImage()!)
}

func pixelBuffer(from image: UIImage, width: Int, height: Int) -> CVPixelBuffer? {
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: true,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     width,
                                     height,
                                     kCVPixelFormatType_OneComponent8,
                                     attrs,
                                     &pixelBuffer)

    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        return nil
    }

    CVPixelBufferLockBaseAddress(buffer, [])

    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: CGColorSpaceCreateDeviceGray(),
                            bitmapInfo: 0)!

    guard let cgImage = image.cgImage else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    CVPixelBufferUnlockBaseAddress(buffer, [])

    return buffer
}
