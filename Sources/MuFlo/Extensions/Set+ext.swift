
public extension Set {
    
    func hasAny(_ other: Self) -> Bool {
        let result = self.intersection(other).count > 0
        return result
    }
}
