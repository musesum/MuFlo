// created by musesum on 10/14/24

import SwiftUI

@Observable public class ArchiveItem: Identifiable, Equatable {

    public static func == (lhs: ArchiveItem, rhs: ArchiveItem) -> Bool { lhs.id == rhs.id }
    public var id = Visitor.nextId()
    var name : String
    var icon : Image
    var url  : URL?
    var spot = false
    var title: String
    var time: TimeInterval
    var genius: String? // genius prepare post

    init(_ name: String,
         _ icon: UIImage,
         _ description: String?,
         _ url: URL?) {

        self.name = name
        self.icon = Image(uiImage: icon)
        self.url = url
        self.title = name.trimNonLetterPrefix

        if let numberString = name.numericPrefix,
           let time = TimeInterval(numberString)
        {
            self.time = time
        } else {
            self.time = Date().timeIntervalSince1970
        }

        self.genius =
        "{\n" +
        "\"id\": \"\(name)\",\n" +
        "\"title\": \"\(title)\",\n" +
        "\"description\": \"\(description ?? "")\",\n" +
        "\"external_url\": \"\(url?.absoluteString ?? "")\",\n" +
        "\"image_url\": \"\(url?.absoluteString ?? "")\"\n" +
        "},"
        print(genius!)
    }
}
