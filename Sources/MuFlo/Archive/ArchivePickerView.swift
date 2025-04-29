// created by musesum on 10/6/24

import SwiftUI

public struct ArchivePickerView: View {

    let archiveVm: ArchiveVm
    @State var gridColumns = Array(repeating: GridItem(.flexible()), count: 3)

    public init(_ archiveVm: ArchiveVm) {
        self.archiveVm = archiveVm
    }
    public var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: gridColumns) {
                ForEach(archiveVm.archiveActs) {
                    ArchiveItemView(archiveVm, $0)
                }
            }
            .padding()
        }
    }
}

public struct ArchiveItemView: View {
    let archiveVm: ArchiveVm
    let archiveItem: ArchiveItem
    var isCurrent: Bool { archiveItem.name == archiveVm.nameNow }
    var stroke: Color { isCurrent ? .white : .clear }
    var width: CGFloat { isCurrent ? 2.0 : 0 }

    init(_ archiveVm: ArchiveVm,
         _ archiveItem: ArchiveItem) {

        self.archiveVm = archiveVm
        self.archiveItem = archiveItem
    }
    func open(_ archiveItem: ArchiveItem, _ taps: Int) {
        archiveVm.archiveAction(archiveItem, taps)
    }

    public var body: some View {

        MultiTapButton(tapOnce: { open(archiveItem, 1) },
                       tapTwice: { open(archiveItem, 2) },
                       longPress: { open(archiveItem, 3) }) {

            VStack {
                archiveItem.icon
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16)) // clip corners
                    .overlay(RoundedRectangle(cornerRadius:  16)
                        .stroke(stroke, lineWidth: width)
                        .background(.clear)
                    )
                    .shadow(color: .black, radius: 1.0)
                Text(archiveItem.name)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1.0)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
            }
        }
    }
}
