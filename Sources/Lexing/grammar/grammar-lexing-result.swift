import Position

public extension LexingResult {
    /// Construct a canonical lossless result directly from typed, byte-located tokens.
    /// This avoids reconstructing deprecated Character ranges for grammar lexemes.
    init(source: String, tokens: [LocatedToken]) throws {
        let size = source.utf8.count
        var boundaries: Set<Int> = [0]
        var offset = 0
        for scalar in source.unicodeScalars {
            offset += scalar.utf8.count
            boundaries.insert(offset)
        }

        var expected = 0
        var seenEOF = false
        for (index, lexeme) in tokens.enumerated() {
            let start = lexeme.range.lowerBound.offset
            let end = lexeme.range.upperBound.offset
            guard start <= end, boundaries.contains(start), boundaries.contains(end) else {
                throw TokenCoverage.Failure.invalid_range(index: index)
            }
            if lexeme.token == .eof {
                guard index == tokens.count - 1, !seenEOF else {
                    throw TokenCoverage.Failure.premature_eof(index: index)
                }
                guard start == size, end == size, expected == size else {
                    throw TokenCoverage.Failure.invalid_eof(index: index, offset: expected)
                }
                seenEOF = true
                continue
            }
            guard !seenEOF else { throw TokenCoverage.Failure.premature_eof(index: index) }
            if start < expected {
                throw TokenCoverage.Failure.overlap(index: index, expected: expected, actual: start)
            }
            if start > expected {
                throw TokenCoverage.Failure.gap(index: index, expected: expected, actual: start)
            }
            if start == end {
                guard case .error = lexeme.token else {
                    throw TokenCoverage.Failure.invalid_range(index: index)
                }
            }
            expected = end
        }
        guard seenEOF else { throw TokenCoverage.Failure.missing_eof }
        self.source = source
        self.tokens = tokens
        self.diagnostics = tokens.compactMap { lexeme in
            guard case .error(let message, _) = lexeme.token else { return nil }
            return LexicalDiagnostic(message: message, range: lexeme.range)
        }
    }
}
