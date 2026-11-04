import Foundation

public extension Lexer.Block {
    struct Options: Sendable, Equatable {
        public var trimWhitespace: Bool = false
        public var unquoteIfWrapped: Bool = false
        public var unescapeCommon: Bool = false
        public var normalizeNewlines: Bool = false

        public init(
            trimWhitespace: Bool = false,
            unquoteIfWrapped: Bool = false,
            unescapeCommon: Bool = false,
            normalizeNewlines: Bool = false
        ) {
            self.trimWhitespace = trimWhitespace
            self.unquoteIfWrapped = unquoteIfWrapped
            self.unescapeCommon = unescapeCommon
            self.normalizeNewlines = normalizeNewlines
        }
    }

    struct Policy: Sendable, Equatable {
        public var delimiter: Delimiter = .braces
        public var options: Options = .init()

        public init(delimiter: Delimiter = .braces, options: Options = .init()) {
            self.delimiter = delimiter
            self.options = options
        }
    }

    struct Policies: Sendable {
        public var predetermined: [String: Policy] = [:]
        public var fallback: Policy

        public init(
            predetermined: [String: Policy] = [:],
            fallback: Policy
        ) {
            self.predetermined = predetermined
            self.fallback = fallback
        }

        public func policy(for keyword: String) -> Policy {
            predetermined[keyword] ?? fallback
        }
    }
}
