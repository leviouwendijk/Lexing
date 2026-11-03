extension Lexer {
    struct CursorCheckpoint: Sendable {
        let index: Int
        let line: Int
        let column: Int
    }

    func checkpoint() -> CursorCheckpoint {
        .init(index: index, line: line, column: column)
    }

    mutating func restore(_ checkpoint: CursorCheckpoint) {
        index = checkpoint.index
        line = checkpoint.line
        column = checkpoint.column
    }
}
