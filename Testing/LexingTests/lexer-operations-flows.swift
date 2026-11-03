import Lexing
import Testing

extension LexingTestSuite {
    static var operationsSuite: TestSuite {
        TestSuite("lexer-operations") {
            Test("speculative scan restores state on failure") {
                var lexer = Lexer(source: "2026-xx-yy", sets: .init(keywords: []))
                try Expect.equal(lexer.scan.date_literal(), nil, "not a date")
                try Expect.equal(lexer.index, 0, "cursor restored")
                try Expect.equal(lexer.column, 1, "column restored")
            }

            Test("read commits and mutates the original value") {
                var lexer = Lexer(source: "\"hello\"", sets: .init(keywords: []))
                try Expect.equal(try lexer.read.quoted(), "hello", "quoted string")
                try Expect.equal(lexer.nextToken(), .eof, "cursor was updated")
            }

            Test("block reader balances nested delimiters") {
                var lexer = Lexer(source: "{a{b}c}", sets: .init(keywords: []))
                try Expect.equal(try lexer.read.block(.braces), "a{b}c", "nested block")
                try Expect.equal(lexer.nextToken(), .eof, "block was consumed")
            }

            Test("collect toggles positional mapping without changing token values") {
                var mapped = Lexer(source: "alpha beta", sets: .init(keywords: []))
                let result = mapped.tokens.collect(map: true)
                try Expect.equal(result.values, [.identifier("alpha"), .identifier("beta"), .eof], "tokens")
                try Expect.equal(result.ranges?.count, 3, "aligned ranges")
                try Expect.equal(result.lexed?.count, 3, "lexed view")
                try Expect.equal(mapped.nextToken(), .eof, "writeback")

                var plain = Lexer(source: "alpha beta", sets: .init(keywords: []))
                let plainResult = plain.tokens.collect(map: false)
                try Expect.equal(plainResult.values, result.values, "same values")
                try Expect.equal(plainResult.ranges == nil, true, "unmapped")
            }
        }
    }
}
