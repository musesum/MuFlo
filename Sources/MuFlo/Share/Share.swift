// created by musesum on 8/14/25
#if !os(watchOS)
import Foundation
import MuPeers

public struct Share: Sendable {
    public let peers: Peers
    public let tapeFlo: TapeFlo
    public init(_ peers: Peers, _ tapeFlo: TapeFlo) {
        self.peers = peers
        self.tapeFlo = tapeFlo
    }
}
#endif

