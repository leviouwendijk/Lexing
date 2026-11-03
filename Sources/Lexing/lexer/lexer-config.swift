import Foundation
import Position

public extension Lexer {
    enum ErrorStrategy: Sendable {
        case throwing
        case error_token
        case diagnose_only(@Sendable (String, Position) -> Void)
    }

    struct Config: Sendable {
        public var errorStrategy: ErrorStrategy = .throwing
        public var unescapeStringsInLexer = true

        public init() {}
    }
}
