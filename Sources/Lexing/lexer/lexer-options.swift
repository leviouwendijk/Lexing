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

        // Preserve existing language defaults until the grammar separation pass.
        public var block: Block = .init(policies: .init(
            predetermined: [
                ["details"]: .init(
                    delimiter: .braces,
                    options: .init(
                        trimWhitespace: true,
                        unquoteIfWrapped: true,
                        unescapeCommon: true,
                        normalizeNewlines: true
                    )
                ),
                ["raw"]: .init(
                    delimiter: .braces,
                    options: .init(
                        trimWhitespace: false,
                        unquoteIfWrapped: false,
                        unescapeCommon: false,
                        normalizeNewlines: false
                    )
                )
            ],
            fallback: .init(
                delimiter: .braces,
                options: .init(
                    trimWhitespace: true,
                    unquoteIfWrapped: false,
                    unescapeCommon: false,
                    normalizeNewlines: true
                )
            )
        ))

        public var comments: [CommentSignature] = [
            .line(prefix: "//"),
            .line(prefix: "#"),
            .block(start: "/*", end: "*/", allows_nesting: false)
        ]

        public var normalize_newlines: Bool = true

        public init() {}

        /// Explicit lossless emission policy. The existing default is unchanged.
        public static var lossless: Self {
            var options = Self()
            options.emit = .init(whitespace: true, newlines: true, comments: true)
            options.unsupported = .error_token
            return options
        }
    }
}
