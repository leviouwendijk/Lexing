import Lexing
import Testing

extension LexingTestSuite {
    static var operationsSuite: TestSuite {
        TestSuite("lexer-operations") {
            Test("scalar cursor lookahead never indexes outside the source") {
                var lexer = Lexer(source: "ab", sets: .init(keywords: []))
                try Expect.equal(lexer.peek(), "a", "initial scalar")
                try Expect.equal(lexer.peek(aheadBy: -1), nil, "negative lookahead")
                try Expect.equal(lexer.peek(aheadBy: Int.max), nil, "overflow-safe lookahead")
                lexer.advance()
                try Expect.equal(lexer.peek(), "b", "second scalar")
                try Expect.equal(lexer.peek(aheadBy: 1), nil, "past source end")
                lexer.advance()
                try Expect.equal(lexer.peek(), nil, "end of source")
                try Expect.equal(lexer.peek(aheadBy: Int.max), nil, "EOF lookahead")
            }

            Test("speculative scan restores a midstream cursor") {
                var lexer = Lexer(source: "alpha\n2026-xx-yy", sets: .init(keywords: []))
                try Expect.equal(lexer.nextToken(), .identifier("alpha"), "prefix")
                try Expect.equal(lexer.nextToken(), .newline, "newline")
                let index = lexer.index
                let location = lexer.loc()
                try Expect.equal(lexer.scan.date_literal(), nil, "invalid date")
                try Expect.equal(lexer.index, index, "scalar index")
                try Expect.equal(lexer.loc().line, location.line, "source line")
                try Expect.equal(lexer.loc().column, location.column, "source column")
            }

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
