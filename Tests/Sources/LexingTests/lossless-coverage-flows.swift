import Lexing
import Position
import Testing

extension LexingTestSuite {
    static var losslessCoverageSuite: TestSuite {
        TestSuite("lossless-coverage") {
            Test("complete source coverage includes trivia, errors and CRLF") {
                let source = " α // note\r\n\"🙂\" !"
                let coverage = try TokenCoverage.collect(
                    source: source, sets: .init(keywords: [])
                )
                let categories = coverage.lexemes.map { $0.token.category }
                try Expect.equal(categories, [
                    .whitespace, .identifier, .whitespace, .comment, .newline,
                    .string, .whitespace, .invalid, .eof
                ], "all source components are represented")
                try Expect.equal(coverage.lexemes.last?.utf8Range?.lowerBound.offset,
                                 source.utf8.count, "EOF ends at exact byte length")
            }

            Test("lossless coverage handles empty source and standalone CR") {
                let empty = try TokenCoverage.collect(source: "", sets: .init(keywords: []))
                try Expect.equal(empty.lexemes.map(\.token), [.eof], "empty source")
                let source = "a\rb"
                let result = try TokenCoverage.collect(source: source, sets: .init(keywords: []))
                try Expect.equal(result.lexemes.map(\.token), [
                    .identifier("a"), .newline, .identifier("b"), .eof
                ], "standalone CR is a newline")
            }

            Test("canonical lexing result has nonoptional byte spans and diagnostics") {
                let source = "a🙂\r\n"
                let result = try LexingResult.collect(source: source, sets: .init(keywords: []))
                try Expect.equal(result.source, source, "immutable source retained")
                try Expect.equal(result.tokens.last?.range.lowerBound.offset, source.utf8.count,
                                 "EOF at exact byte boundary")
                try Expect.equal(result.diagnostics.count, 1, "unsupported scalar is diagnosed")
                try Expect.equal(result.diagnostics[0].range.lowerBound.offset, 1,
                                 "emoji byte range begins after ASCII")
                try Expect.equal(result.diagnostics[0].range.upperBound.offset, 5,
                                 "emoji spans four UTF-8 bytes")
            }

            Test("gaps and missing provenance fail explicitly") {
                let missing = LexedToken(
                    token: .identifier("a"),
                    range: PositionRange(uncheckedStart: .init(0), uncheckedEnd: .init(1))
                )
                try Expect.throwsError("unlocated lexical data cannot claim coverage") {
                    _ = try TokenCoverage(source: "a", lexemes: [missing])
                }
                try Expect.throwsError("default lexer skips whitespace") {
                    _ = try TokenCoverage.collect(source: "a b", sets: .init(keywords: []), options: .init())
                }
            }
        }
    }
}
