import Errors
import Foundation
import Position

public extension Lexer {
    enum Error: Swift.Error {
        case unexpectedEOF(context: String, at: Position)
        case unterminated(delimiter: String, at: Position)
        case invalidEscape(sequence: String, at: Position)
        case invalidNumber(raw: String, at: Position)
        case emptyIdentifier(at: Position)
        case invalidDateLiteral(raw: String, at: Position)
        case message(String, at: Position)
    }
}

extension Lexer.Error:
    SemanticError,
    ErrorNamespaced,
    ErrorDispositionProviding
{
    public static let errorNamespace = "lexing"

    public var errorCode: String {
        switch self {
        case .unexpectedEOF: return "unexpected_end"
        case .unterminated: return "unterminated"
        case .invalidEscape: return "invalid_escape"
        case .invalidNumber: return "invalid_number"
        case .emptyIdentifier: return "empty_identifier"
        case .invalidDateLiteral: return "invalid_date_literal"
        case .message: return "invalid_source"
        }
    }

    public var errorPresentation: ErrorPresentation {
        let at = "at \(position.line):\(position.column)"
        switch self {
        case .unexpectedEOF(let context, _):
            return .init(message: "Unexpected end of input while reading \(context) \(at).")
        case .unterminated(let delimiter, _):
            return .init(
                message: "Unterminated block \(at).",
                recoverySuggestion: "Close it with \(delimiter)."
            )
        case .invalidEscape(let sequence, _):
            return .init(
                message: "Invalid escape sequence \\\(sequence) \(at).",
                messageSensitivity: .potentially_sensitive
            )
        case .invalidNumber(let raw, _):
            return .init(
                message: "Invalid number '\(raw)' \(at).",
                messageSensitivity: .potentially_sensitive
            )
        case .emptyIdentifier:
            return .init(message: "Expected an identifier \(at).")
        case .invalidDateLiteral(let raw, _):
            return .init(
                message: "Invalid date literal '\(raw)' \(at).",
                messageSensitivity: .potentially_sensitive
            )
        case .message(let message, _):
            return .init(message: "\(message) \(at).")
        }
    }

    public var errorDiagnosticFields: [ErrorDiagnosticField] {
        position.errorFields
    }

    /// The source must change.
    public var errorDisposition: ErrorDisposition? {
        .invalid_input
    }

    public var position: Position {
        switch self {
        case .unexpectedEOF(_, let at),
             .unterminated(_, let at),
             .invalidEscape(_, let at),
             .invalidNumber(_, let at),
             .emptyIdentifier(let at),
             .invalidDateLiteral(_, let at),
             .message(_, let at):
            return at
        }
    }
}

extension Position {
    /// `source.file`, `source.line` and `source.column`, for an error's diagnostics.
    public var errorFields: [ErrorDiagnosticField] {
        (file.map { [.init(key: "source.file", value: $0, sensitivity: .potentially_sensitive)] } ?? []) + [
            .init(key: "source.line", value: line),
            .init(key: "source.column", value: column),
        ]
    }
}
