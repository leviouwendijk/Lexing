import Foundation

public extension Lexer {
    @inline(__always)
    func peek() -> UnicodeScalar? {
        index < scalars.count ? scalars[index] : nil
    }

    @inline(__always)
    func peek(aheadBy n: Int) -> UnicodeScalar? {
        let j = index + n
        return j < scalars.count ? scalars[j] : nil
    }

    @inline(__always)
    mutating func advance() {
        guard index < scalars.count else { return }
        let s = scalars[index]
        index += 1
        if s == "\r" {
            line += 1
            column = 1
        } else if s == "\n" {
            if index < 2 || scalars[index - 2] != "\r" { line += 1 }
            column = 1
        } else {
            column += 1
        }
    }
}
