public extension Lexer {
    struct Config: Sendable {
        public var unescapeQuoted: Bool

        public init(unescapeQuoted: Bool = true) {
            self.unescapeQuoted = unescapeQuoted
        }
    }
}
