import Errors

extension GrammarLexer.Failure:
    SemanticError,
    ErrorNamespaced,
    ErrorDispositionProviding
{
    public static let errorNamespace = "lexing.grammar"

    public var errorCode: String {
        switch self {
        case .invalid_pattern: return "invalid_pattern"
        case .unsupported_extra: return "unsupported_extra"
        case .conflicting_extra_terminal: return "conflicting_extra_terminal"
        }
    }

    public var errorPresentation: ErrorPresentation {
        switch self {
        case .invalid_pattern(let pattern):
            return .init(
                message: "The terminal pattern '\(pattern)' cannot be used.",
                reason: "A pattern must be a valid regular expression that cannot match empty input."
            )
        case .unsupported_extra:
            return .init(
                message: "An extra is neither a terminal, a literal, a pattern nor a choice of those."
            )
        case .conflicting_extra_terminal(let name):
            return .init(
                message: "The terminal '\(name)' is both an extra and part of the grammar."
            )
        }
    }

    public var errorDiagnosticFields: [ErrorDiagnosticField] {
        switch self {
        case .invalid_pattern(let pattern):
            return [.init(key: "grammar.pattern", value: pattern)]
        case .conflicting_extra_terminal(let name):
            return [.init(key: "grammar.symbol", value: name)]
        case .unsupported_extra:
            return []
        }
    }

    /// A grammar is code: it holds until its definition changes.
    public var errorDisposition: ErrorDisposition? {
        .permanent
    }
}

extension Lexer.Specification.Failure:
    SemanticError,
    ErrorNamespaced,
    ErrorDispositionProviding
{
    public static let errorNamespace = "lexing.specification"

    public var errorCode: String {
        switch self {
        case .conflicting_identifier: return "conflicting_identifier"
        case .missing_block_policy: return "missing_block_policy"
        case .unsupported_delimiter: return "unsupported_delimiter"
        case .invalid_comment_signature: return "invalid_comment_signature"
        case .ambiguous_comment_signature: return "ambiguous_comment_signature"
        case .requires_lossless_emission: return "requires_lossless_emission"
        }
    }

    public var errorPresentation: ErrorPresentation {
        switch self {
        case .conflicting_identifier(let name):
            return .init(message: "'\(name)' is both an identifier and a keyword.")
        case .missing_block_policy(let keyword):
            return .init(message: "The string block keyword '\(keyword)' has no block policy.")
        case .unsupported_delimiter(let start):
            return .init(
                message: "'\(start)' is not a supported block delimiter.",
                recoverySuggestion: "Use {}, [], () or <>."
            )
        case .invalid_comment_signature:
            return .init(message: "A comment signature has an empty start or end.")
        case .ambiguous_comment_signature(let prefix):
            return .init(message: "The comment start '\(prefix)' overlaps another comment start.")
        case .requires_lossless_emission:
            return .init(
                message: "The specification drops source text.",
                reason: "Whitespace, newlines and comments must be emitted and unsupported text kept as error tokens."
            )
        }
    }

    public var errorDisposition: ErrorDisposition? {
        .permanent
    }
}
