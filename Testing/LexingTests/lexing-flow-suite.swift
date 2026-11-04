import Testing

enum LexingTestSuite {
    static let suite = TestSuite(
        "lexing",
        title: "Lexing tests"
    ) {
        lexicalProvenanceSuite
        tokenCodableSuite
        correctnessSuite
        apiSuite
        operationsSuite
        losslessCoverageSuite
    }
}
