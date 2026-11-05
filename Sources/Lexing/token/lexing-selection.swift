import Position

public extension LexingResult {
    /// Token views are projections of one immutable, lossless source snapshot.
    enum Selection: Sendable {
        case all
        case without_spacing
        case significant
    }

    func select(_ selection: Selection) -> [LocatedToken] {
        tokens.filter { located in
            if case .eof = located.token { return true }
            if case .error = located.token { return true }
            switch selection {
            case .all:
                return true
            case .without_spacing:
                switch located.token {
                case .whitespace, .comment_line, .comment_block, .grammar_extra: return false
                default: return true
                }
            case .significant:
                return !located.token.is_trivia
            }
        }
    }

    var eof: Position.Offset<Position.Unit.UTF8> {
        tokens[tokens.count - 1].range.upperBound
    }
}
