//  created by musesum on 7/23/21.

import SwiftUI
import ZIPFoundation

public class ArchiveZip {

    private var URL: URL
    private var name: String
    private var ext: String
    private var archive: Archive!
    private let Files = FileManager.default

    public var archiveTime: TimeInterval!

    public init?(_ name: String,
                 _ ext: String,
                 _ accessMode: Archive.AccessMode = .update) {

        self.name = name
        self.ext = ext
        URL = Files.docURL.appendingPathComponent(name)
        URL.appendPathExtension(ext)
        archive = getArchive(accessMode) ?? getArchive(.create)
        if archive == nil { return nil }
        archiveTime = Files.documentDate(name, ext)
    }

    public init?(_ url: URL, accessMode: Archive.AccessMode) {

        self.ext = url.pathExtension
        self.name = url.deletingPathExtension().lastPathComponent

        URL = url

        archive = (accessMode == .read
                   ? getArchive(.read) ?? getArchive(.create)
                   : getArchive(.update) ?? getArchive(.create))
        if archive == nil { return nil }
    }
    private func getArchive(_ mode: Archive.AccessMode) -> Archive? {
        do {
            let archive = try Archive(url: URL, accessMode: mode, pathEncoding: nil)
            return archive
        } catch {
            PrintLog("⁉️ \(#function) could not open \(self.name)")
            return nil
        }
    }

    public func addName(_ path: String, ext: String, data: Data) {

        guard let archive else { return err(path + " not found") }

        do {
            try archive.addEntry(with: path + "." + ext,
                                 type: .file,
                                 uncompressedSize: Int64(data.count),
                                 compressionMethod: .deflate) { (position, size)  in
                let pos = Int(position)
                return data.subdata(in: pos ..< (pos + size))
            }
        }
        catch { err("\(error)") }

        func err(_ msg: String) { PrintLog("⁉️ ArchiveZip::addName \(msg)") }
    }

    public func readFile(_ filename: String,
                         showError: Bool = true) -> Data? {

        guard let archive else { return err("archive (\(name)) = nil") }
        let path = name + "/" + filename
        let urlName = filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        guard let entry = (archive[filename] ??
                           archive[path] ??
                           archive[urlName]) else {
            return err("archive \(path) not found") }

        var data = Data()
        do {
            _ = try archive.extract(entry, bufferSize: 1_000_000)  { crc32 in
                data.append(crc32)
            }
            return data
        }
        catch { return err("\(error)") }

        func err(_ msg: String) -> Data?{
            if showError {
                PrintLog("⁉️ ArchiveZip::readFile \(msg)")
            }
            return nil
        }
    }
    public func replace(_ at: String,  with: String) {
        
        let atURL = Files.docURL.appendingPathComponent(at).appendingPathExtension(ext)
        let withURL = Files.docURL.appendingPathComponent(with).appendingPathExtension(ext)

        do {
            _ = try Files.replaceItemAt(atURL, withItemAt: withURL)
        }
        catch {
            PrintLog("⁉️ ArchiveZip::replace could not replace \(at) with: \(with)")
        }
    }


}
