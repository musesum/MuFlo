// created by musesum on 10/6/24

import SwiftUI

@Observable public class ArchiveVm: FloId, Identifiable {

    public static let shared = ArchiveVm()
    public var archiveProto: ArchiveProto?
    public var archiveActs: [ArchiveItem] { getArchiveMus() }
    private let Files = FileManager.default
    public var nameNow = "Archive"

    func archiveAction(_ archiveItem: ArchiveItem,_ taps: Int) {
        switch taps {
        case 1,2:
            if let archiveProto,
               let url = archiveItem.url {
                archiveProto.readUserArchive(url, local: true)
            }
            nameNow = archiveItem.name
        default: break
        }
    }
    public func getArchiveMus() -> [ArchiveItem] {
        var archiveActs = [ArchiveItem]()
        let urls = Files.contentsOf(ext: "mu")
        for url in urls {
            if let archive = ArchiveZip(url, accessMode: .read),
               let data = archive.readFile("icon.png"),
               let icon = UIImage(data: data) {

                let name = url.deletingPathExtension().lastPathComponent
                let item  = ArchiveItem(name, icon, url)
                archiveActs.append(item)
            }
        }
        return archiveActs
    }
}
