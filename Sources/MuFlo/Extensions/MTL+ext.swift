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
    func makeBuffer(_ rect: CGRect, _ label: String? = nil) -> MTLBuffer? {
        let simd4 = SIMD4<Float>(rect)
        let size = MemoryLayout<SIMD4<Float>>.size
        let buf = makeBuffer(bytes: [simd4], length: size, options: .storageModeShared)
        if let label {
            buf?.label = label
        }
        return buf
    }
    func makeBuffer(_ size: CGSize, _ label: String? = nil) -> MTLBuffer? {
        let simd2 = SIMD2<Float>(size)
        let size = MemoryLayout<SIMD2<Float>>.size
        return makeBuffer(bytes: [simd2], length: size, options: .storageModeShared)
    }
    func makeBuffer(_ point: CGPoint, _ label: String? = nil) -> MTLBuffer? {
        let simd2 = SIMD2<Float>(point)
        let size = MemoryLayout<SIMD2<Float>>.size
        let buf = makeBuffer(bytes: [simd2], length: size, options: .storageModeShared)
        if let label {
            buf?.label = label
        }
        return buf
    }
    func makeBuffer(_ uint: UInt, _ label: String? = nil) -> MTLBuffer? {
        let size = MemoryLayout<UInt>.size
        let val = UInt(uint)
        let buf = makeBuffer(bytes: [val], length: size, options: .storageModeShared)
        if let label {
            buf?.label = label
        }
        return buf
    }
}

public extension MTLTexture {
    
    func rawBytes() -> (UnsafeMutableRawPointer, Int) {
        
        let width = self.width
        let height = self.height
        let pixSize = MemoryLayout<UInt32>.size
        let rowBytes = self.width * pixSize
        let totalSize = width * height * pixSize
        let data = malloc(totalSize)!
        self.getBytes(data, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return (data, totalSize)
    }
    func rawData() -> Data? {
        let (bytes, totalSize) = rawBytes()
        let rawData = Data.init(bytes: bytes, count: totalSize)
        return rawData
    }

    func toImage() -> CGImage? {
        let pixSize = MemoryLayout<UInt32>.size
        let (data, totalSize) = rawBytes()
        
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
    var aspect: Aspect {
        
        width > height ? .landscape :
        width < height ? .portrait : .square
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
extension MTLRenderCommandEncoder {
    public func setFragmentTexture(_ flo: Flo?, index: Int) {

        if let tex = flo?.texture {
            setFragmentTexture (tex, index: index)
        }
    }
    public func setVertexTexture(_ flo: Flo?, index: Int) {

        if let tex = flo?.texture {
            setVertexTexture (tex, index: index)
        }
    }
    public func setVertexBuffer(_ flo: Flo?, index: Int) {

        if let buf = flo?.buffer {
            setVertexBuffer (buf, offset: 0, index: index)
        }
    }
    public func setFragmentBuffer(_ flo: Flo?, index: Int) {

        if let buf = flo?.buffer {
            setFragmentBuffer (buf, offset: 0, index: index)
        }
    }

}
extension MTLComputeCommandEncoder {

    public func setTexture(_ flo: Flo?, index: Int) {

        if let tex = flo?.texture {
            setTexture (tex, index: index)
        }
    }
    public func setBuffer(_ flo: Flo?, index: Int) {

        if let buf = flo?.buffer {
            setBuffer (buf, offset: 0, index: index)
        }
    }
}
extension CAMetalLayer {
    public var aspect: Aspect {
        drawableSize.width / drawableSize.height > 1 ? .landscape : .portrait
    }
    public var isLandscape: Bool { aspect == .landscape }
    public var isPortrait: Bool { aspect == .portrait }
}
