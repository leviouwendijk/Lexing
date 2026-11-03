public extension Lexer {
    struct Config: Sendable {
        public var unescapeQuoted: Bool

        public init() {
            self.unescapeQuoted = true
        }

        public init(unescapeQuoted: Bool) {
            self.unescapeQuoted = unescapeQuoted
        }
    }
}
