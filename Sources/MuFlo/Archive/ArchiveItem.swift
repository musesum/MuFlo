// created by musesum on 10/14/24

import SwiftUI

@Observable public class ArchiveItem: FloId, Identifiable, Equatable {

    public static func == (lhs: ArchiveItem, rhs: ArchiveItem) -> Bool { lhs.id == rhs.id }
    var name : String
    var icon : Image
    var url  : URL?
    var spot = false

    init(_ name: String,
         _ icon: UIImage,
         _ url: URL?) {

        self.name = name
        self.icon = Image(uiImage: icon)
        self.url = url
    }

    init(_ name: String,
         _ icon: Image) {
        self.name = name
        self.icon = icon
    }
}
