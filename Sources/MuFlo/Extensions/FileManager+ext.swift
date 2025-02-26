//  FileManager+extension.swift
//  created by musesum on 9/23/19.

import Foundation

public extension FileManager {

    var docURL: URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func documentDate(_ fileName: String,
                      _ ext: String) -> TimeInterval {
        let documentsURL = urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = documentsURL.path + "/" + fileName + "." + ext
        let date = getFileTime(path)
        if date == 0 { PrintLog("⁉️ MuFile::documentDate missing \(fileName) ") }
        return date
    }
    func pathDate(_ filePath: String) -> TimeInterval {
        return getFileTime( filePath)
    }

    /**
     Get creation date from file.  is explicitely set and should match between devices.
     */
    func getFileTime(_ filePath: String) -> TimeInterval {

        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileDate = (fileAttributes[FileAttributeKey.modificationDate] as? NSDate)!
            let fileTime = fileDate.timeIntervalSince1970
            //DebugLog { P("⧉ \(#function) \(fileTime)") }
            return fileTime
        }
        catch  { }
        return 0
    }

    func urls(for directory: FileManager.SearchPathDirectory,
              skipsHiddenFiles: Bool = true ) -> [URL]? {

       let fileURLs = try? contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }

    func contentsOf(ext: String?) -> [URL] {
        do {
            let allFiles = try contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil)
            if let ext {
                return allFiles.filter{ $0.pathExtension == ext }
            } else  {
                return allFiles
            }
        }
        catch {
            PrintLog("⁉️ FileManager::contentsOf(\(ext ?? "")) \(error)")
            return []
        }
    }

    func removeItemIfExist(at url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            PrintLog("⁉️ FileManager::contentsOf(at: \(url.relativeString)) \(error)")
        }
    }
}

