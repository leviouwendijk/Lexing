import Foundation

public extension Lexer {
    struct Options: Sendable {
        public enum UnsupportedScalarPolicy: Sendable {
            case error_token
            case skip
        }

        public enum IdentifierContinuation: Sendable {
            case dotted_hyphenated
            case punctuation_delimited
        }

        public struct Emit: Sendable {
            public var whitespace: Bool
            public var newlines: Bool
            public var comments: Bool

            public init(
                whitespace: Bool = false,
                newlines: Bool = true,
                comments: Bool = false
            ) {
                self.whitespace = whitespace
                self.newlines = newlines
                self.comments = comments
            }
        }

        public struct Block: Sendable {
            public var policies: Lexer.Block.Policies

            public init(policies: Lexer.Block.Policies) {
                self.policies = policies
            }
        }

        public var unsupported: UnsupportedScalarPolicy = .error_token
        public var identifier: IdentifierContinuation = .dotted_hyphenated
        public var emit: Emit = .init()

        // Language-specific block keywords and body normalization belong to consumers.
        public var block: Block = .init(policies: .init(fallback: .init()))

        public var comments: [CommentSignature] = [
            .line(prefix: "//"),
            .line(prefix: "#"),
            .block(start: "/*", end: "*/", allows_nesting: false)
        ]

        public var normalize_newlines: Bool = true

        /// The low-level Lexer preserves its historical implicit date matching.
        /// Canonical lossless specifications disable it unless requested.
        public var recognize_dates: Bool = true

        public init() {}

        /// Explicit lossless emission policy. The existing default is unchanged.
        public static var lossless: Self {
            var options = Self()
            options.emit = .init(whitespace: true, newlines: true, comments: true)
            options.unsupported = .error_token
            options.recognize_dates = false
            return options
        }
    }
}
