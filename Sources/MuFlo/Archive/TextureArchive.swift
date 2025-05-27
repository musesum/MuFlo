// created by musesum on 11/16/24

import Foundation
import Metal
#if canImport(UIKit)
import UIKit
#endif

public func textureToPngData(_ tex: MTLTexture) -> Data? {
    let width = tex.width
    let height = tex.height
    let bytesPerPixel = 4 // Assuming RGBA8 format
    let bytesPerRow = bytesPerPixel * width
    var imageData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

    // Copy texture data into the array
    let region = MTLRegionMake2D(0, 0, width, height)
    tex.getBytes(&imageData, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

    // Create a CGImage from the raw data
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    //let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    //let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue))
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    let data = NSData(bytes: &imageData, length: imageData.count)
    if let providerRef = CGDataProvider(data:data),
       let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: providerRef,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) {
        let image = UIImage(cgImage: cgImage)
        return image.pngData()
    }
    return nil
}

public func pngDataToTexture(_ data: Data) -> MTLTexture? {
    guard let device = MTLCreateSystemDefaultDevice(),
          let image = UIImage(data: data),
          let cgImage = image.cgImage else {
        return nil
    }

    let width = cgImage.width
    let height = cgImage.height

    let td = MTLTextureDescriptor()
    td.pixelFormat = .bgra8Unorm
    td.width = width
    td.height = height
    td.usage = [.shaderRead, .shaderWrite]

    guard let texture = device.makeTexture(descriptor: td) else {
        return nil
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    var rawPngData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

    // Create a bitmap context
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    let frame = CGRect(x: 0, y: 0, width: width, height: height)

    guard let context = CGContext(
        data: &rawPngData,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        return nil
    }

    // Draw the CGImage into the context
    context.draw(cgImage, in: frame)

    // Copy the data into the texture
    let region = MTLRegionMake2D(0, 0, width, height)
    rawPngData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
        if let baseAddress = pointer.baseAddress {
            texture.replace(region: region, mipmapLevel: 0, withBytes: baseAddress, bytesPerRow: bytesPerRow)
        }
    }

    return texture
} 
