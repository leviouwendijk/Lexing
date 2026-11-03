import Position

public struct LexedToken: Sendable, Codable, Hashable {
    public let token: Token
    public let range: PositionRange
    /// Exact half-open byte offsets, including boundaries inside a Swift Character.
    /// Nil for legacy LexedToken values without byte provenance.
    public let utf8Range: Range<Position.Offset<Position.Unit.UTF8>>?

    public init(
        token: Token,
        range: PositionRange,
        utf8Range: Range<Position.Offset<Position.Unit.UTF8>>? = nil
    ) {
        self.token = token
        self.range = range
        self.utf8Range = utf8Range
    }
}
