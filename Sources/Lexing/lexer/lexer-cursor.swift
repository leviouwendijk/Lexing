import Foundation

public extension Lexer {
    @inline(__always)
    func peek() -> UnicodeScalar? {
        guard index >= 0, index < scalars.count else { return nil }
        return scalars[index]
    }

    @inline(__always)
    func peek(aheadBy n: Int) -> UnicodeScalar? {
        guard index >= 0, index < scalars.count,
              n >= 0, n < scalars.count - index else {
            return nil
        }
        return scalars[index + n]
    }

    @inline(__always)
    mutating func advance() {
        guard index >= 0, index < scalars.count else { return }
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
