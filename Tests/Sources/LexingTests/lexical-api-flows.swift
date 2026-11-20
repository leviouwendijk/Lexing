import Lexing
import Testing

extension LexingTestSuite {
    static var apiSuite: TestSuite {
        TestSuite("lexing-api") {
            Test("canonical lexer names are stable") {
                try Expect.equal(Delimiter.quotes_double.start, "\"", "double quote preset")
                try Expect.equal(Delimiter.quotes_single.start, "'", "single quote preset")
                try Expect.equal(Token.less_than.samecase(as: .less_than), true, "samecase")
                try Expect.equal(Token.less_than.samecase(as: .greater_than), false, "distinct cases")
            }

            Test("explicit identifiers override keyword and block classification") {
                var lexer = Lexer(
                    source: "raw reserved plain",
                    sets: .init(
                        keywords: ["raw", "reserved"],
                        idents: ["raw", "reserved"],
                        stringBlockKeywords: ["raw"]
                    )
                )
                try Expect.equal(
                    lexer.tokens.collect(map: false).values,
                    [.identifier("raw"), .identifier("reserved"), .identifier("plain"), .eof],
                    "explicit identifier precedence"
                )
            }

            Test("error tokens match their own enum case") {
                var lexer = Lexer(source: "?", sets: .init(keywords: []))
                let token = lexer.nextToken()
                try Expect.equal(token.samecase(as: token), true, "reflexive error case")
                try Expect.equal(token.samecase(as: .eof), false, "distinct cases")
            }

            Test("canonical declarations resolve to nested types") {
                let _: Lexer.Options = Lexer.Options()
                let _: Lexer.Config = Lexer.Config()
                let _: Lexer.Vocabulary = Lexer.Vocabulary(keywords: [])
                let _: Lexer.Block.Options = Lexer.Block.Options()
                let _: Lexer.Block.Policy = Lexer.Block.Policy()
                let _: Lexer.Block.State = Lexer.Block.State.none
                try Expect.equal(
                    String(reflecting: Lexer.Options.self).contains("Lexer.Options"),
                    true,
                    "canonical options identity"
                )
                var options = Lexer.Options()
                options.emit.whitespace = true
                options.emit.whitespace = false
                try Expect.equal(options.emit.whitespace, false, "canonical field write")
                options.block.policies = .init(fallback: .init(delimiter: .parens))
                try Expect.equal(options.block.policies.fallback.delimiter, .parens, "block storage")
            }

            Test("nested options write back to underlying settings") {
                let _: Lexer.Vocabulary = .init(keywords: [])
                var options = Lexer.Options()
                options.emit.whitespace = true
                options.emit.comments = true
                options.unsupported = .skip
                options.identifier = .punctuation_delimited
                try Expect.equal(options.emit.whitespace, true, "whitespace")
                try Expect.equal(options.emit.comments, true, "comments")
                try Expect.equal(options.unsupported == .skip, true, "unsupported")
                try Expect.equal(
                    options.identifier == .punctuation_delimited,
                    true,
                    "identifier"
                )
            }
        }
    }
}
