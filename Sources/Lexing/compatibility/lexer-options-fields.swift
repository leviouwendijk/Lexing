public extension Lexer.Options {
    var unsupported_scalars: UnsupportedScalarPolicy {
        get { unsupported }
        set { unsupported = newValue }
    }

    var identifier_continuation: IdentifierContinuation {
        get { identifier }
        set { identifier = newValue }
    }

    var emit_whitespace: Bool {
        get { emit.whitespace }
        set { emit.whitespace = newValue }
    }

    var emit_newlines: Bool {
        get { emit.newlines }
        set { emit.newlines = newValue }
    }

    var emit_comments: Bool {
        get { emit.comments }
        set { emit.comments = newValue }
    }

    var block_string_policies: Lexer.Block.Policies {
        get { block.policies }
        set { block.policies = newValue }
    }
}
