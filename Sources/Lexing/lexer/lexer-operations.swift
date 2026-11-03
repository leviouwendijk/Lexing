import Foundation
import Position

public extension Lexer {
    struct Scan {
        fileprivate var lexer: Lexer

        public mutating func date_literal() -> String? {
            lexer.scanDateLiteral()
        }
    }

    struct Read {
        fileprivate var lexer: Lexer

        public mutating func quoted() throws -> String {
            let at = lexer.loc()
            guard lexer.match("\"") else {
                throw LexerError.message("Expected opening double quote", at: at)
            }
            guard let text = lexer.readQuotedLiteral() else {
                throw LexerError.unterminated(delimiter: "\"", at: at)
            }
            return text
        }

        public mutating func block(
            _ delimiter: Delimiter,
            options: Lexer.Block.Options = .init()
        ) throws -> String {
            let at = lexer.loc()
            guard !delimiter.start.isEmpty, !delimiter.end.isEmpty,
                  lexer.match(delimiter.start) else {
                throw LexerError.message("Expected opening delimiter", at: at)
            }
            let text = lexer.readUntilClosing(delimiter: delimiter, options: options)
            guard lexer.match(delimiter.end) else {
                throw LexerError.unterminated(delimiter: delimiter.end, at: at)
            }
            return text
        }
    }

    struct Tokens {
        fileprivate var lexer: Lexer

        public struct Collection: Sendable {
            public let values: [Token]
            public let ranges: [PositionRange]?

            public var lexed: [LexedToken]? {
                guard let ranges, ranges.count == values.count else { return nil }
                return zip(values, ranges).map {
                    LexedToken(token: $0.0, range: $0.1)
                }
            }
        }

        public mutating func collect(map: Bool = true) -> Collection {
            if map {
                let values = lexer.lexedTokens()
                return Collection(
                    values: values.map(\.token),
                    ranges: values.map(\.range)
                )
            }
            return Collection(values: lexer.collectAllTokens(), ranges: nil)
        }
    }

    var scan: Scan {
        get { Scan(lexer: self) }
        set { self = newValue.lexer }
    }

    var read: Read {
        get { Read(lexer: self) }
        set { self = newValue.lexer }
    }

    var tokens: Tokens {
        get { Tokens(lexer: self) }
        set { self = newValue.lexer }
    }
}
