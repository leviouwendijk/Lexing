import Lexing
import Testing

extension LexingTestSuite {
    static var apiSuite: TestSuite {
        TestSuite("lexing-api") {
            Test("canonical names and compatibility are equivalent") {
                try Expect.equal(Delimiter.quotes_double, .doubleQuotes, "double quote alias")
                try Expect.equal(Delimiter.quotes_single, .singleQuotes, "single quote alias")
                try Expect.equal(Token.less_than.samecase(as: .less_than), true, "samecase")
                try Expect.equal(Token.less_than.samecase(as: .greater_than), false, "distinct cases")
                try Expect.equal(Token.less_than.sameCase(as: .less_than), true, "legacy alias")
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

            Test("canonical declarations retain legacy aliases") {
                let _: Lexer.Options = LexerOptions()
                let _: Lexer.Config = LexerConfig()
                let _: Lexer.Vocabulary = LexingSets(keywords: [])
                let _: Lexer.Block.Options = BlockStringOptions()
                let _: Lexer.Block.Policy = BlockStringPolicy()
                let _: Lexer.Block.State = LexStringBlockState.none
                try Expect.equal(
                    String(reflecting: Lexer.Options.self).contains("Lexer.Options"),
                    true,
                    "canonical options identity"
                )
                var options = Lexer.Options()
                options.emit.whitespace = true
                options.emit_whitespace = false
                try Expect.equal(options.emit.whitespace, false, "legacy field forwards")
                options.block_string_policies = .init(fallback: .init(delimiter: .parens))
                try Expect.equal(options.block.policies.fallback.delimiter, .parens, "block storage")
            }

            Test("nested options write back to underlying settings") {
                let _: Lexer.Vocabulary = .init(keywords: [])
                var options = Lexer.Options()
                options.emit.whitespace = true
                options.emit.comments = true
                options.unsupported = .skip
                options.identifier = .punctuation_delimited
                try Expect.equal(options.emit_whitespace, true, "whitespace")
                try Expect.equal(options.emit_comments, true, "comments")
                try Expect.equal(options.unsupported_scalars == .skip, true, "unsupported")
                try Expect.equal(
                    options.identifier_continuation == .punctuation_delimited,
                    true,
                    "identifier"
                )
            }
        }
    }
}
