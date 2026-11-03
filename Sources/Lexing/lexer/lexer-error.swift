import Foundation
import Position

public extension Lexer {
    enum Error: Swift.Error, LocalizedError {
    case unexpectedEOF(context: String, at: Position)
    case unterminated(delimiter: String, at: Position)
    case invalidEscape(sequence: String, at: Position)
    case invalidNumber(raw: String, at: Position)
    case emptyIdentifier(at: Position)
    case invalidDateLiteral(raw: String, at: Position)
    case message(String, at: Position)

    public var errorDescription: String? {
        switch self {
        case .unexpectedEOF(let ctx, let at):
            return "Unexpected end of input while reading \(ctx) at \(at.line):\(at.column)."
        case .unterminated(let d, let at):
            return "Unterminated block; expected closing \(d) at \(at.line):\(at.column)."
        case .invalidEscape(let seq, let at):
            return "Invalid escape sequence \\\(seq) at \(at.line):\(at.column)."
        case .invalidNumber(let raw, let at):
            return "Invalid number '\(raw)' at \(at.line):\(at.column)."
        case .emptyIdentifier(let at):
            return "Expected identifier at \(at.line):\(at.column)."
        case .invalidDateLiteral(let raw, let at):
            return "Invalid date literal '\(raw)' at \(at.line):\(at.column)."
        case .message(let m, let at): 
            return "\(m) at \(at.line):\(at.column)" 
        }
    }
    }
}

