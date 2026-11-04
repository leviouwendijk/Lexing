import Position

/// A lexeme with mandatory UTF-8 provenance, independent of decoded payloads.
public struct LocatedToken: Sendable, Hashable {
    public let token: Token
    public let range: Range<Position.Offset<Position.Unit.UTF8>>

    public init(token: Token, range: Range<Position.Offset<Position.Unit.UTF8>>) {
        self.token = token
        self.range = range
    }
}

public struct LexicalDiagnostic: Sendable, Hashable {
    public let message: String
    public let range: Range<Position.Offset<Position.Unit.UTF8>>

    public init(message: String, range: Range<Position.Offset<Position.Unit.UTF8>>) {
        self.message = message
        self.range = range
    }
}

/// Lossless canonical lexer output; legacy LexedToken remains an adapter.
public struct LexingResult: Sendable {
    public let source: String
    public let tokens: [LocatedToken]
    public let diagnostics: [LexicalDiagnostic]

    public init(coverage: TokenCoverage) throws {
        self.source = coverage.source
        self.tokens = try coverage.lexemes.enumerated().map { index, lexeme in
            guard let range = lexeme.utf8Range else {
                throw TokenCoverage.Failure.missing_provenance(index: index)
            }
            return LocatedToken(token: lexeme.token, range: range)
        }
        self.diagnostics = tokens.compactMap { token in
            guard case .error(let message, _) = token.token else { return nil }
            return LexicalDiagnostic(message: message, range: token.range)
        }
    }

    public static func collect(
        source: String,
        sets: Lexer.Vocabulary,
        options: Lexer.Options = .lossless,
        config: Lexer.Config = .init()
    ) throws -> Self {
        try Self(coverage: TokenCoverage.collect(
            source: source, sets: sets, options: options, config: config
        ))
    }
}
