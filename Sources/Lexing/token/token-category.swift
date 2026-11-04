public extension Token {
    enum Category: String, Codable, Hashable, Sendable {
        case keyword
        case identifier
        case number
        case string
        case date
        case whitespace
        case newline
        case comment
        case delimiter
        case `operator`
        case punctuation
        case invalid
        case eof
    }

    /// Generic lexical classification; individual languages may refine it.
    var category: Category {
        switch self {
        case .keyword: .keyword
        case .identifier: .identifier
        case .number: .number
        case .string: .string
        case .date_literal: .date
        case .whitespace: .whitespace
        case .newline: .newline
        case .comment_line,
            .comment_block:
            .comment
        case .left_brace,
            .right_brace,
            .left_parenthesis,
            .right_parenthesis,
            .left_bracket,
            .right_bracket:
            .delimiter
        case .arrow,
            .less_than,
            .greater_than,
            .equals,
            .percent,
            .asterisk,
            .ampersand,
            .plus,
            .dash,
            .pipe,
            .forward_slash:
            .operator
        case .dot,
            .comma,
            .hash,
            .dollar,
            .at,
            .underscore,
            .tilde,
            .colon,
            .semicolon,
            .backward_slash,
            .double_quote,
            .single_quote:
            .punctuation
        case .error: .invalid
        case .eof: .eof
        }
    }
}
