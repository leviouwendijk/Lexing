import Lexing
import Testing

extension LexingTestSuite {
    static var specificationSuite: TestSuite {
        TestSuite("lexing-specification") {
            Test("canonical lossless source and token selection") {
                let source = "é  alpha\r\n// comment\nbeta"
                let spec = try Lexer.Specification(vocabulary: .init(keywords: []))
                let result = try spec.lex(source)
                try Expect.equal(result.source, source, "source snapshot")
                try Expect.equal(result.eof.offset, source.utf8.count, "exact EOF")
                try Expect.true(result.select(.all).count > result.select(.without_spacing).count, "trivia selection")
                try Expect.true(result.select(.without_spacing).count > result.select(.significant).count, "newline selection")
                try Expect.equal(result.select(.significant).last?.token, .eof, "EOF retained")
                try Expect.equal(result.select(.all).first?.range.upperBound.offset, 2, "Unicode range")
            }
            Test("date-shaped tokens need explicit canonical recognition") {
                let plain = try Lexer.Specification(vocabulary: .init(keywords: []))
                let recognized = try Lexer.Specification(vocabulary: .init(keywords: []), recognize_dates: true)
                let input = "2026-11-04"
                let regular = try plain.lex(input)
                let dated = try recognized.lex(input)
                try Expect.false(regular.tokens.contains { if case .date_literal = $0.token { true } else { false } }, "default is not a date")
                try Expect.true(dated.tokens.contains { if case .date_literal = $0.token { true } else { false } }, "opt-in date")
            }
            Test("ambiguous vocabularies and missing block policy are rejected") {
                do {
                    _ = try Lexer.Specification(vocabulary: .init(keywords: ["x"], idents: ["x"]))
                    try Expect.true(false, "must reject ambiguous word")
                } catch Lexer.Specification.Failure.conflicting_identifier("x") {}
                do {
                    _ = try Lexer.Specification(vocabulary: .init(keywords: [], stringBlockKeywords: ["raw"]))
                    try Expect.true(false, "must reject missing block policy")
                } catch Lexer.Specification.Failure.missing_block_policy("raw") {}
            }
        }
    }
}
