import Foundation

public struct LexerOptions: Sendable {
    public enum UnsupportedScalarPolicy: Sendable {
        case error_token
        case skip
    }

    /// Unsupported input is observable by default.
    public var unsupported_scalars: UnsupportedScalarPolicy = .error_token
    public enum IdentifierContinuation: Sendable {
        case dotted_hyphenated
        case punctuation_delimited
    }

    public var identifier_continuation: IdentifierContinuation = .dotted_hyphenated

    // Trivia emission
    public var emit_whitespace: Bool = false
    public var emit_newlines: Bool = true
    public var emit_comments: Bool = false

    // public var block_string_policy: BlockStringPolicy = .init(
    //     delimiter: .braces,
    //     options: .init(
    //         trimWhitespace: true,
    //         unquoteIfWrapped: true,
    //         unescapeCommon: true,
    //         normalizeNewlines: true
    //     )
    // )

    public var block_string_policies: BlockPolicyTable = .init(
        predetermined: [
            [
                "details"
            ]: .init(
                delimiter: .braces,
                options: .init(
                    trimWhitespace: true,
                    unquoteIfWrapped: true,
                    unescapeCommon: true,
                    normalizeNewlines: true
                )
            ),

            [
                "raw"
            ]: .init(
                delimiter: .braces,
                options: .init(
                    trimWhitespace: false,
                    unquoteIfWrapped: false,
                    unescapeCommon: false,
                    normalizeNewlines: false
                )
            ),
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
    )

    // Comment syntaxes to recognize
    public var comments: [CommentSignature] = [
        .line(prefix: "//"),
        .line(prefix: "#"),
        .block(start: "/*", end: "*/", allows_nesting: false)
    ]

    // Newline normalization (CRLF -> LF)
    public var normalize_newlines: Bool = true

    public init() {}
}
