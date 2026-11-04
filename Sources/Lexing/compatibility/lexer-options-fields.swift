public extension Lexer.Options {
    @available(*, deprecated, message: "Use unsupported.")
    var unsupported_scalars: UnsupportedScalarPolicy {
        get { unsupported }
        set { unsupported = newValue }
    }

    @available(*, deprecated, message: "Use identifier.")
    var identifier_continuation: IdentifierContinuation {
        get { identifier }
        set { identifier = newValue }
    }

    @available(*, deprecated, message: "Use emit.whitespace.")
    var emit_whitespace: Bool {
        get { emit.whitespace }
        set { emit.whitespace = newValue }
    }

    @available(*, deprecated, message: "Use emit.newlines.")
    var emit_newlines: Bool {
        get { emit.newlines }
        set { emit.newlines = newValue }
    }

    @available(*, deprecated, message: "Use emit.comments.")
    var emit_comments: Bool {
        get { emit.comments }
        set { emit.comments = newValue }
    }

    @available(*, deprecated, message: "Use block.policies.")
    var block_string_policies: Lexer.Block.Policies {
        get { block.policies }
        set { block.policies = newValue }
    }
}
