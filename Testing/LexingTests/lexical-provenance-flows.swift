import Foundation
import Lexing
import Position
import Testing

extension LexingTestSuite {
    static var lexicalProvenanceSuite: TestSuite {
        TestSuite(
            "lexical-provenance",
            tags: ["lexer", "position", "unicode"]
        ) {
            Test("UTF-8 provenance and Character spans agree across CRLF") {
                let source = "é\r\nfoo"
                var lexer = Lexer(source: source, sets: .init(keywords: []))
                let lexed = lexer.lexedTokens()
                try Expect.equal(
                    lexed.map(\.token),
                    [.identifier("é"), .newline, .identifier("foo"), .eof],
                    "lexical sequence"
                )
                try Expect.equal(
                    lexed.map(\.range.offsets),
                    [0..<1, 1..<2, 2..<5, 5..<5],
                    "Character spans"
                )
                try Expect.equal(
                    lexed.map { $0.utf8Range?.lowerBound.offset },
                    [0, 2, 4, 7],
                    "UTF-8 starts"
                )
                try Expect.equal(
                    lexed.map { $0.utf8Range?.upperBound.offset },
                    [2, 4, 7, 7],
                    "UTF-8 ends"
                )
                let location = lexer.loc()
                try Expect.equal(location.line, 2, "EOF line")
                try Expect.equal(location.column, 4, "EOF Character column")
                let map = Position.TextMap(source: source)
                try Expect.equal(
                    try map.range(lexed[2].range, as: Position.Unit.UTF8.self),
                    lexed[2].utf8Range,
                    "explicit Character-to-byte conversion"
                )
            }

            Test("byte provenance resolves partial grapheme spans") {
                let source = "e\u{200D}x"
                var lexer = Lexer(source: source, sets: .init(keywords: []))
                let lexed = lexer.lexedTokens()
                try Expect.equal(lexed[0].token, .identifier("e"), "base letter")
                try Expect.equal(
                    lexed[0].range.offsets,
                    lexed[1].range.offsets,
                    "Character range necessarily overlaps for a split grapheme"
                )
                try Expect.equal(lexed[0].utf8Range?.lowerBound.offset, 0, "base byte start")
                try Expect.equal(lexed[0].utf8Range?.upperBound.offset, 1, "base byte end")
                try Expect.equal(lexed[1].utf8Range?.lowerBound.offset, 1, "mark byte start")
                try Expect.equal(lexed[1].utf8Range?.upperBound.offset, 4, "mark byte end")
                try Expect.equal(lexed[2].utf8Range?.lowerBound.offset, 4, "next token byte start")
            }

            Test("mapped collection retains exact lexeme byte provenance") {
                var lexer = Lexer(source: "é", sets: .init(keywords: []))
                let collected = lexer.tokens.collect(map: true)
                try Expect.equal(collected.lexed?.first?.utf8Range?.upperBound.offset, 2, "retained bytes")
                try Expect.equal(collected.ranges?.first?.end.offset, 1, "Character view")
            }

            Test("positioned lexing uses Character offsets and excludes skipped trivia") {
                let source = "alpha 👨‍👩‍👧‍👦 beta"
                var options = Lexer.Options()
                options.unsupported = .skip
                var lexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: options
                )
                let lexed = lexer.lexedTokens()

                try Expect.equal(
                    lexed.map(\.token),
                    [.identifier("alpha"), .identifier("beta"), .eof],
                    "lexical token sequence"
                )
                try Expect.equal(
                    lexed.map { $0.range.start.offset },
                    [0, 8, 12],
                    "lexical Character start offsets"
                )
                try Expect.equal(
                    lexed.map { $0.range.end.offset },
                    [5, 12, 12],
                    "lexical Character end offsets"
                )
            }

            Test("identifier continuation policy preserves defaults and can expose punctuation") {
                let source = "foo.bar foo-bar"

                var defaultLexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: [])
                )
                let defaultTokens = defaultLexer.lexedTokens().map(\.token)

                var punctuationOptions = Lexer.Options()
                punctuationOptions.identifier = .punctuation_delimited

                var punctuationLexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: punctuationOptions
                )
                let punctuationTokens = punctuationLexer.lexedTokens().map(\.token)

                try Expect.equal(
                    defaultTokens,
                    [
                        .identifier("foo.bar"),
                        .identifier("foo-bar"),
                        .eof,
                    ],
                    "default identifier continuation remains dotted and hyphenated"
                )
                try Expect.equal(
                    punctuationTokens,
                    [
                        .identifier("foo"),
                        .dot,
                        .identifier("bar"),
                        .identifier("foo"),
                        .dash,
                        .identifier("bar"),
                        .eof,
                    ],
                    "punctuation-delimited identifiers expose dot and dash tokens"
                )
            }
            Test("long unsupported scalar run terminates without stack overflow") {
                let source = String(repeating: "!", count: 100_000)
                var options = Lexer.Options()
                options.unsupported = .skip
                var lexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: options
                )

                try Expect.equal(lexer.nextToken(), .eof, "unsupported input reaches EOF")
                try Expect.equal(lexer.nextToken(), .eof, "repeated EOF remains stable")
            }

            Test("long unsupported prefix preserves following token provenance") {
                let source = String(repeating: "^", count: 50_000) + "tail"
                var options = Lexer.Options()
                options.unsupported = .skip
                var lexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: options
                )

                let lexeme = lexer.nextLexedToken()
                try Expect.equal(lexeme.token, .identifier("tail"), "identifier after skipped prefix")
                try Expect.equal(lexeme.range.start.offset, 50_000, "start Character offset")
                try Expect.equal(lexeme.range.end.offset, 50_004, "end Character offset")
                try Expect.equal(lexer.nextToken(), .eof, "EOF after identifier")
            }

            Test("CSV-like input preserves tokens across long unsupported runs") {
                let source = "a," + String(repeating: "!", count: 20_000) + "\nb"
                var options = Lexer.Options()
                options.unsupported = .skip
                var lexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: options
                )
                let lexed = lexer.lexedTokens()

                try Expect.equal(
                    lexed.map(\.token),
                    [.identifier("a"), .comma, .newline, .identifier("b"), .eof],
                    "CSV-like token sequence"
                )
                try Expect.equal(
                    lexed.map { $0.range.start.offset },
                    [0, 1, 20_002, 20_003, 20_004],
                    "CSV-like start offsets"
                )
                try Expect.equal(
                    lexed.map { $0.range.end.offset },
                    [1, 2, 20_003, 20_004, 20_004],
                    "CSV-like end offsets"
                )
            }

            Test("RTF-like input does not recurse through unsupported content") {
                let source = "{\\rtf1 " + String(repeating: "^", count: 20_000) + "body}"
                var options = Lexer.Options()
                options.unsupported = .skip
                var lexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: options
                )

                try Expect.equal(
                    lexer.lexedTokens().map(\.token),
                    [
                        .left_brace,
                        .backward_slash,
                        .identifier("rtf1"),
                        .identifier("body"),
                        .right_brace,
                        .eof
                    ],
                    "RTF-like token sequence"
                )
            }

            Test("extended Unicode skips preserve Character-based offsets") {
                let source = String(repeating: "👨‍👩‍👧‍👦", count: 1_000) + "tail"
                var options = Lexer.Options()
                options.unsupported = .skip
                var lexer = Lexer(
                    source: source,
                    sets: Lexer.Vocabulary(keywords: []),
                    options: options
                )

                let lexeme = lexer.nextLexedToken()
                try Expect.equal(lexeme.token, .identifier("tail"), "token after extended Unicode")
                try Expect.equal(lexeme.range.start.offset, 1_000, "Unicode Character start offset")
                try Expect.equal(lexeme.range.end.offset, 1_004, "Unicode Character end offset")
                try Expect.equal(lexer.nextToken(), .eof, "Unicode input terminates")
            }
        }
    }

    static var tokenCodableSuite: TestSuite {
        TestSuite(
            "token-codable",
            tags: ["codable", "lexed-token", "token"]
        ) {
            Test("Token and LexedToken round-trip as durable lexical values") {
                let start = try Position.Offset<Position.Unit.UTF8>(3)
                let end = try Position.Offset<Position.Unit.UTF8>(8)
                let value = LexedToken(
                    token: .identifier("alpha"),
                    range: PositionRange(
                        uncheckedStart: .init(3),
                        uncheckedEnd: .init(8)
                    ),
                    utf8Range: start..<end
                )
                let encoded = try JSONEncoder().encode(value)
                let decoded = try JSONDecoder().decode(
                    LexedToken.self,
                    from: encoded
                )

                try Expect.equal(decoded, value, "LexedToken Codable round trip")
            }
        }
    }
}
