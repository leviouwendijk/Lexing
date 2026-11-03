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
