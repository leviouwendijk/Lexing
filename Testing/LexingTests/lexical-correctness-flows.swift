import Foundation
import Lexing
import Testing

extension LexingTestSuite {
    static var correctnessSuite: TestSuite {
        TestSuite("lexical-correctness", tags: ["correctness", "diagnostics"]) {
            Test("suppressed newline and indentation preserve nested tokens") {
                var options = Lexer.Options()
                options.emit.newlines = false
                options.emit.whitespace = false
                let source = "outer {\n    inner {}\n}"
                var lexer = Lexer(
                    source: source,
                    sets: .init(keywords: []),
                    options: options
                )
                let collection = lexer.tokens.collect(map: true)
                try Expect.equal(
                    collection.values,
                    [
                        .identifier("outer"), .left_brace,
                        .identifier("inner"), .left_brace, .right_brace,
                        .right_brace, .eof
                    ],
                    "suppressed trivia must not become errors"
                )
                try Expect.equal(collection.ranges?[2].start.offset, 12, "nested identifier offset")
            }

            Test("emitted newlines survive suppressed indentation") {
                var lexer = Lexer(source: "outer {\n    inner", sets: .init(keywords: []))
                try Expect.equal(
                    lexer.tokens.collect(map: false).values,
                    [.identifier("outer"), .left_brace, .newline, .identifier("inner"), .eof],
                    "emitted newline remains visible"
                )
            }

            Test("suppressed comments do not produce unsupported newline errors") {
                var options = Lexer.Options()
                options.emit.comments = false
                options.emit.newlines = false
                let source = "// note\nname = \"one\"\n/* hidden */\nname = \"two\""
                var lexer = Lexer(
                    source: source,
                    sets: .init(keywords: []),
                    options: options
                )
                let collection = lexer.tokens.collect(map: true)
                try Expect.equal(
                    collection.values,
                    [
                        .identifier("name"), .equals, .string("one"),
                        .identifier("name"), .equals, .string("two"), .eof
                    ],
                    "two parsed assignments with comments suppressed"
                )
                try Expect.equal(collection.ranges?.first?.start.offset, 8, "first identifier start")
                try Expect.equal(collection.ranges?.last?.end.offset, source.count, "source EOF")
            }

            Test("suppressed comment still allows newline emission") {
                var lexer = Lexer(source: "// note\nname", sets: .init(keywords: []))
                try Expect.equal(
                    lexer.tokens.collect(map: false).values,
                    [.newline, .identifier("name"), .eof],
                    "newline remains visible after a suppressed comment"
                )
            }

            Test("punctuation case comparison is reflexive and distinct") {
                try Expect.equal(Token.less_than.sameCase(as: .less_than), true, "less-than matches itself")
                try Expect.equal(Token.greater_than.sameCase(as: .greater_than), true, "greater-than matches itself")
                try Expect.equal(Token.less_than.sameCase(as: .greater_than), false, "distinct punctuation")
            }

            Test("unsupported scalars emit errors without erasing following input") {
                var lexer = Lexer(source: "!ok", sets: LexingSets(keywords: []))
                let tokens = lexer.lexedTokens()
                try Expect.equal(tokens.count, 3, "error, identifier, EOF")
                if case .error = tokens[0].token {
                    try Expect.equal(tokens[0].range.start.offset, 0, "error start")
                    try Expect.equal(tokens[0].range.end.offset, 1, "error end")
                } else {
                    try Expect.equal(true, false, "first token must be a lexical error")
                }
                try Expect.equal(tokens[1].token, .identifier("ok"), "preserved identifier")
                try Expect.equal(tokens[2].token, .eof, "real EOF")
            }

            Test("unrepresentable numeric literal is not coerced to zero") {
                var lexer = Lexer(source: "٢٢", sets: LexingSets(keywords: []))
                let first = lexer.nextToken()
                if case .error = first {
                    try Expect.equal(lexer.nextToken(), .eof, "error followed by EOF")
                } else {
                    try Expect.equal(true, false, "numeric conversion must fail explicitly")
                }
            }

            Test("failed date lookahead restores index, line and column") {
                var lexer = Lexer(source: "2026-xx-yy tail", sets: LexingSets(keywords: []))
                let result = lexer.scanDateLiteral()
                try Expect.equal(result, nil, "not a date")
                try Expect.equal(lexer.index, 0, "index restored")
                try Expect.equal(lexer.line, 1, "line restored")
                try Expect.equal(lexer.column, 1, "column restored")
            }

            Test("unterminated quote reports an error and then EOF") {
                var lexer = Lexer(source: "\"unfinished", sets: LexingSets(keywords: []))
                if case .error = lexer.nextToken() {
                    try Expect.equal(lexer.nextToken(), .eof, "EOF only after error")
                } else {
                    try Expect.equal(true, false, "unterminated quote must report an error")
                }
            }

            Test("missing string-block opening delimiter reports an error") {
                var lexer = Lexer(
                    source: "raw value",
                    sets: LexingSets(keywords: [], stringBlockKeywords: ["raw"])
                )
                try Expect.equal(lexer.nextToken(), .keyword("raw"), "block trigger")
                if case .error = lexer.nextToken() {
                    try Expect.equal(lexer.nextToken(), .identifier("value"), "remaining input retained")
                } else {
                    try Expect.equal(true, false, "missing opener must report an error")
                }
            }

            Test("unterminated block and comment report errors") {
                var block = Lexer(
                    source: "raw {body",
                    sets: LexingSets(keywords: [], stringBlockKeywords: ["raw"])
                )
                try Expect.equal(block.nextToken(), .keyword("raw"), "block trigger")
                try Expect.equal(block.nextToken(), .left_brace, "opening brace")
                try Expect.equal(block.nextToken(), .string("body"), "body retained")
                if case .error = block.nextToken() {
                    try Expect.equal(block.nextToken(), .eof, "block EOF follows error")
                } else {
                    try Expect.equal(true, false, "unterminated block must report an error")
                }

                var comment = Lexer(source: "/* open", sets: LexingSets(keywords: []))
                if case .error = comment.nextToken() {
                    try Expect.equal(comment.nextToken(), .eof, "comment EOF follows error")
                } else {
                    try Expect.equal(true, false, "unterminated comment must report an error")
                }
            }
        }
    }
}
