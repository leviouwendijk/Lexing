import Position

/// Verifies exact, contiguous coverage of source bytes by located lexemes.
/// Payloads may be decoded or normalized: only provenance ranges are tested.
public struct TokenCoverage: Sendable {
    public enum Failure: Swift.Error, Equatable, Sendable {
        case missing_eof
        case premature_eof(index: Int)
        case missing_provenance(index: Int)
        case gap(index: Int, expected: Int, actual: Int)
        case overlap(index: Int, expected: Int, actual: Int)
        case invalid_range(index: Int)
        case invalid_eof(index: Int, offset: Int)
    }

    public let source: String
    public let lexemes: [LexedToken]

    public init(source: String, lexemes: [LexedToken]) throws {
        let length = source.utf8.count
        var cursor = 0
        var sawEOF = false
        var boundaries: Set<Int> = [0]
        var boundary = 0
        for scalar in source.unicodeScalars {
            boundary += scalar.utf8.count
            boundaries.insert(boundary)
        }

        for (index, lexeme) in lexemes.enumerated() {
            guard let range = lexeme.utf8Range else {
                throw Failure.missing_provenance(index: index)
            }
            let start = range.lowerBound.offset
            let end = range.upperBound.offset
            guard start >= 0, end >= start, end <= length,
                  boundaries.contains(start), boundaries.contains(end) else {
                throw Failure.invalid_range(index: index)
            }
            if lexeme.token == .eof {
                guard index == lexemes.count - 1, !sawEOF else {
                    throw Failure.premature_eof(index: index)
                }
                guard cursor == length, start == length, end == length else {
                    throw Failure.invalid_eof(index: index, offset: cursor)
                }
                sawEOF = true
                continue
            }
            guard !sawEOF else { throw Failure.premature_eof(index: index) }
            if start < cursor { throw Failure.overlap(index: index, expected: cursor, actual: start) }
            if start > cursor { throw Failure.gap(index: index, expected: cursor, actual: start) }
            if start == end {
                guard case .error = lexeme.token else {
                    throw Failure.invalid_range(index: index)
                }
            }
            cursor = end
        }
        guard sawEOF else { throw Failure.missing_eof }
        self.source = source
        self.lexemes = lexemes
    }

    public static func collect(
        source: String,
        sets: Lexer.Vocabulary,
        options: Lexer.Options = .lossless,
        config: Lexer.Config = .init()
    ) throws -> Self {
        var lexer = Lexer(source: source, sets: sets, options: options, config: config)
        return try Self(source: source, lexemes: lexer.lexedTokens())
    }
}
