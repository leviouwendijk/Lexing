public extension Lexer {
    // Legacy readers retain their original preconsumption contracts.
    mutating func readQuotedLiteral() -> String? {
        _quoted_body()
    }

    mutating func readUntilClosing(
        delimiter: Delimiter,
        options: Lexer.Block.Options
    ) -> String {
        _block_body(delimiter: delimiter, options: options)
    }

    mutating func scanDateLiteral() -> String? {
        _date_literal()
    }
}
