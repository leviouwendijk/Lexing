public extension Delimiter {
    // Compatibility aliases for external clients.
    @available(*, deprecated, renamed: "quotes_double")
    static var doubleQuotes: Self { .quotes_double }
    @available(*, deprecated, renamed: "quotes_single")
    static var singleQuotes: Self { .quotes_single }
}
