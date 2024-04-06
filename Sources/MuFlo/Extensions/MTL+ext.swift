// created by musesum on 12/21/23

import simd
import ModelIO
import MetalKit

public extension MTLVertexDescriptor {
    
    var modelVD: MDLVertexDescriptor {
        
        let mdlDescriptor = MDLVertexDescriptor()
        
        // Map the attribute indices to names
        let attributeNames = [
            MDLVertexAttributePosition,
            MDLVertexAttributeNormal,
            MDLVertexAttributeTextureCoordinate,
            // Add more mappings as needed
        ]
        for (index, name) in attributeNames.enumerated() {
            if let mtlAttribute = self.attributes[index], mtlAttribute.format != .invalid {
                let mdlAttribute = MDLVertexAttribute(
                    name: name,
                    format: MDLVertexFormat(rawValue: mtlAttribute.format.rawValue)!,
                    offset: mtlAttribute.offset,
                    bufferIndex: mtlAttribute.bufferIndex)
                mdlDescriptor.attributes[index] = mdlAttribute
            }
        }
        // Metal typically supports up to 4 vertex buffer layouts
        for i in 0..<4 {
            if let mtlLayout = self.layouts[i],
               mtlLayout.stride != 0 {
                let mdlLayout = MDLVertexBufferLayout(stride: mtlLayout.stride)
                mdlDescriptor.layouts[i] = mdlLayout
            }
        }
        return mdlDescriptor
    }
}

public extension MTLDevice {
    
    func load(_ textureName: String) -> MTLTexture {
        do {
            let textureLoader = MTKTextureLoader(device: self)
            
            let textureLoaderOptions = [
                MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
            ]
            
            return try textureLoader.newTexture(name: textureName,
                                                scaleFactor: 1.0,
                                                bundle: nil,
                                                options: textureLoaderOptions)
        } catch {
            fatalError("\(#function) Error: \(error)")
        }
    }
}

public extension MTLTexture {
    
    func mtlBytes() -> (UnsafeMutableRawPointer, Int) {
        
        let width = self.width
        let height = self.height
        let pixSize = MemoryLayout<UInt32>.size
        let rowBytes = self.width * pixSize
        let totalSize = width * height * pixSize
        let data = malloc(totalSize)!
        self.getBytes(data, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return (data, totalSize)
    }
    
    func toImage() -> CGImage? {
        let pixSize = MemoryLayout<UInt32>.size
        let (data, totalSize) = mtlBytes()
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawBitmapInfo = (CGImageAlphaInfo.noneSkipFirst.rawValue |
                             CGBitmapInfo.byteOrder32Little.rawValue)
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        
        let rowBytes = self.width * pixSize
        let releaseCallback: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: data, size: totalSize, releaseData: releaseCallback)
        
        let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        
        return cgImageRef
    }
}


public extension MTLViewport {
    init(_ size: SIMD2<Float>) {
        self.init(originX : 0,
                  originY : 0,
                  width   : Double(size.x),
                  height  : Double(size.y),
                  znear   :0,
                  zfar    :1)
    }
}
