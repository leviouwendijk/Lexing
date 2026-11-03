import Foundation

public extension Lexer.Block {
    enum State: Sendable {
        case none
        case awaitingOpen
        case awaitingContent
        case awaitingClose
    }
}

public protocol Lexing: Sendable {
    var scalars: [UnicodeScalar] { get }
    var index: Int { get set }
    var line: Int { get set }
    var column: Int { get set }
    var string_block_state: Lexer.Block.State { get set }
    mutating func nextToken() -> Token
}
