public extension LexerOptions {
    struct Emit: Sendable {
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

    var emit: Emit {
        get {
            Emit(
                whitespace: emit_whitespace,
                newlines: emit_newlines,
                comments: emit_comments
            )
        }
        set {
            emit_whitespace = newValue.whitespace
            emit_newlines = newValue.newlines
            emit_comments = newValue.comments
        }
    }

    var unsupported: UnsupportedScalarPolicy {
        get { unsupported_scalars }
        set { unsupported_scalars = newValue }
    }

    var identifier: IdentifierContinuation {
        get { identifier_continuation }
        set { identifier_continuation = newValue }
    }

    struct Block: Sendable {
        public var policies: BlockPolicyTable

        public init(policies: BlockPolicyTable) {
            self.policies = policies
        }
    }

    var block: Block {
        get { Block(policies: block_string_policies) }
        set { block_string_policies = newValue.policies }
    }
}
