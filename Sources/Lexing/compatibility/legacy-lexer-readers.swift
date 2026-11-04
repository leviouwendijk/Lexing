public extension Lexer {
    // Legacy readers retain their original preconsumption contracts.
    @available(*, deprecated, message: "Use read.quoted() (which consumes its opening delimiter).")
    mutating func readQuotedLiteral() -> String? {
        _quoted_body()
    }

    @available(*, deprecated, message: "Use read.block(_:options:) (which consumes its opening delimiter).")
    mutating func readUntilClosing(
        delimiter: Delimiter,
        options: Lexer.Block.Options
    ) -> String {
        _block_body(delimiter: delimiter, options: options)
    }

    @available(*, deprecated, message: "Use scan.date_literal().")
    mutating func scanDateLiteral() -> String? {
        _date_literal()
    }
}
