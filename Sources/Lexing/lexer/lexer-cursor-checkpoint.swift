extension Lexer {
    struct CursorCheckpoint: Sendable {
        let index: Int
        let line: Int
        let column: Int
    }

    func cursorCheckpoint() -> CursorCheckpoint {
        .init(index: index, line: line, column: column)
    }

    mutating func restoreCursor(_ checkpoint: CursorCheckpoint) {
        index = checkpoint.index
        line = checkpoint.line
        column = checkpoint.column
    }
}
