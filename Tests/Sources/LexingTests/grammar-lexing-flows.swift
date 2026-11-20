import Grammar
import Lexing
import Testing

extension LexingTestSuite {
    static var grammarLexingSuite: TestSuite {
        TestSuite("grammar-driven-lexing") {
            Test("named terminals, inline literals and extras preserve every byte") {
                let language = try language()
                let lexer = try GrammarLexer(language: language)
                let source = "let alpha = beta\r\nlet gamma = delta"
                let result = try lexer.lex(source)
                try Expect.equal(result.eof.offset, source.utf8.count, "EOF")
                try Expect.equal(result.diagnostics.count, 0, "no lexical errors")
                try Expect.equal(result.tokens.filter { $0.token.is_trivia }.count, 7,
                                 "spaces and CRLF are source-backed extras")
                try Expect.equal(result.select(.significant).count, 9,
                                 "eight terminals and EOF")
                try Expect.equal(result.tokens.first?.token,
                                 .grammar_terminal(name: "let_keyword", raw: "let"),
                                 "tie resolves in declaration order")
            }
            Test("longest match wins at equal lexical priority") {
                let lexer = try GrammarLexer(language: language())
                let result = try lexer.lex("letter")
                try Expect.equal(result.tokens.first?.token,
                                 .grammar_terminal(name: "identifier", raw: "letter"),
                                 "identifier is longer than keyword prefix")
            }
            Test("lexical priority wins over length when explicitly assigned") {
                let grammar = try Grammar.Language(name: "priority", start: "start", productions: [
                    .init(name: "start", expression: .symbol(.terminal("keyword")))
                ], terminals: [
                    .init(name: "keyword", pattern: .literal("let"), lexicalPriority: 3),
                    .init(name: "identifier", pattern: .regex("[a-z]+"))
                ])
                let result = try GrammarLexer(language: grammar).lex("letter")
                try Expect.equal(result.tokens.first?.token,
                                 .grammar_terminal(name: "keyword", raw: "let"),
                                 "explicit lexical priority")
            }
            Test("invalid Unicode retains exact UTF-8 diagnostic range") {
                let result = try GrammarLexer(language: language()).lex("let x = 🐕")
                try Expect.equal(result.diagnostics.count, 1, "one unrecognized scalar")
                let range = result.diagnostics[0].range
                try Expect.equal(range.lowerBound.offset, 8, "emoji start")
                try Expect.equal(range.upperBound.offset, 12, "emoji is four bytes")
            }
            Test("empty input produces a located EOF") {
                let result = try GrammarLexer(language: language()).lex("")
                try Expect.equal(result.tokens.map(\.token), [.eof], "empty source")
                try Expect.equal(result.eof.offset, 0, "zero-length EOF")
            }
        }
    }

    private static func language() throws -> Grammar.Language {
        try Grammar.Language(name: "assignment", start: "file", productions: [
            .init(name: "file", expression: .repeat1(.symbol(.production("assignment")))),
            .init(name: "assignment", expression: .sequence([
                .symbol(.terminal("let_keyword")),
                .field("name", .symbol(.terminal("identifier"))),
                .literal("="),
                .field("value", .symbol(.terminal("identifier")))
            ]))
        ], terminals: [
            .init(name: "let_keyword", pattern: .literal("let"), role: "keyword"),
            .init(name: "identifier", pattern: .regex("[a-z]+"), role: "variable")
        ], extras: [.pattern("[ \\t\\r\\n]+")])
    }
}
