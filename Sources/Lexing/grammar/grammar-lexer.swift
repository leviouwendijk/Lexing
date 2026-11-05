import Foundation
import Grammar
import Position

/// A tokenizing backend for declarative Grammar.Language definitions.
/// It does not change the behavior of the existing hand-written Lexer.
public struct GrammarLexer: Sendable {
    public enum Failure: Swift.Error, Sendable, Equatable {
        case invalid_pattern(String)
        case unsupported_extra
        case conflicting_extra_terminal(String)
    }

    private enum Kind: Sendable {
        case terminal(String)
        case extra
    }

    private enum Matcher: Sendable {
        case literal(String)
        case regular(NSRegularExpression)
    }

    private struct Rule: Sendable {
        let kind: Kind
        let matcher: Matcher
        let priority: Int
        let order: Int
    }

    private let rules: [Rule]

    public init(language: Grammar.Language) throws {
        _ = try language.analyze()

        var extraTerminals: Set<String> = []
        var extraPatterns: [Grammar.Pattern] = []
        for expression in language.extras {
            try Self.collectExtra(
                expression,
                terminals: &extraTerminals,
                patterns: &extraPatterns
            )
        }

        var rules: [Rule] = []
        for terminal in language.terminals {
            let referencedInProductions = language.productions.contains {
                Self.referencesTerminal($0.expression, named: terminal.name)
            }
            if extraTerminals.contains(terminal.name) && referencedInProductions {
                throw Failure.conflicting_extra_terminal(terminal.name)
            }
            let kind: Kind = extraTerminals.contains(terminal.name)
                ? .extra : .terminal(terminal.name)
            try Self.append(terminal.pattern, kind: kind,
                            priority: terminal.lexicalPriority, to: &rules)
        }

        // Inline literal/pattern expressions are lexical rules, not a second grammar.
        var inlineSeen: Set<String> = []
        for production in language.productions {
            try Self.collectInline(production.expression, seen: &inlineSeen, into: &rules)
        }
        for pattern in extraPatterns {
            try Self.append(pattern, kind: .extra, priority: 0, to: &rules)
        }
        self.rules = rules
    }

    /// Emit all source bytes, including trivia and invalid scalars, exactly once.
    public func lex(_ source: String) throws -> LexingResult {
        let nsSource = source as NSString
        let totalUTF16 = nsSource.length
        let lines = LineTable(text: source)
        var utf16Cursor = 0
        var tokens: [LocatedToken] = []

        while utf16Cursor < totalUTF16 {
            let search = NSRange(location: utf16Cursor, length: totalUTF16 - utf16Cursor)
            var selected: (rule: Rule, range: Range<String.Index>, bytes: Int)?

            for rule in rules {
                guard let candidate = Self.match(rule.matcher, source: source,
                                                 nsSource: nsSource, search: search) else {
                    continue
                }
                let length = source[candidate].utf8.count
                guard length > 0 else { continue }
                if let current = selected {
                    if rule.priority < current.rule.priority { continue }
                    if rule.priority == current.rule.priority {
                        if length < current.bytes { continue }
                        if length == current.bytes && rule.order >= current.rule.order { continue }
                    }
                }
                selected = (rule, candidate, length)
            }

            if let selected {
                let raw = String(source[selected.range])
                let token: Token
                switch selected.rule.kind {
                case .terminal(let name):
                    token = .grammar_terminal(name: name, raw: raw)
                case .extra:
                    token = .grammar_extra(raw)
                }
                tokens.append(try Self.locate(token, in: source, over: selected.range))
                utf16Cursor = selected.range.upperBound.utf16Offset(in: source)
                continue
            }

            // A failed match always consumes exactly one Unicode scalar.
            let start = String.Index(utf16Offset: utf16Cursor, in: source)
            let end = source.unicodeScalars.index(after: start)
            let raw = String(source[start..<end])
            let position = lines.position(
                at: PositionIndex(source[..<start].count), file: nil
            )
            let token = Token.error("Unrecognized grammar input '\(raw)'", at: position)
            tokens.append(try Self.locate(token, in: source, over: start..<end))
            utf16Cursor = end.utf16Offset(in: source)
        }

        let end = try Position.Offset<Position.Unit.UTF8>(source.utf8.count)
        tokens.append(LocatedToken(token: .eof, range: end..<end))
        return try LexingResult(source: source, tokens: tokens)
    }

    private static func match(
        _ matcher: Matcher,
        source: String,
        nsSource: NSString,
        search: NSRange
    ) -> Range<String.Index>? {
        let match: NSRange
        switch matcher {
        case .literal(let value):
            let width = (value as NSString).length
            guard width > 0, width <= search.length else { return nil }
            let candidate = NSRange(location: search.location, length: width)
            guard nsSource.substring(with: candidate) == value else { return nil }
            match = candidate
        case .regular(let regex):
            guard let found = regex.firstMatch(
                in: source, options: [.anchored], range: search
            )?.range, found.location == search.location, found.length > 0 else {
                return nil
            }
            match = found
        }
        return Range(match, in: source)
    }

    private static func locate(
        _ token: Token,
        in source: String,
        over range: Range<String.Index>
    ) throws -> LocatedToken {
        let lower = try Position.Offset<Position.Unit.UTF8>(
            source.utf8.distance(from: source.utf8.startIndex, to: range.lowerBound)
        )
        let upper = try Position.Offset<Position.Unit.UTF8>(
            source.utf8.distance(from: source.utf8.startIndex, to: range.upperBound)
        )
        return LocatedToken(token: token, range: lower..<upper)
    }

    private static func append(
        _ pattern: Grammar.Pattern,
        kind: Kind,
        priority: Int,
        to rules: inout [Rule]
    ) throws {
        let matcher: Matcher
        switch pattern {
        case .literal(let text):
            guard !text.isEmpty else { throw Failure.invalid_pattern(text) }
            matcher = .literal(text)
        case .regex(let pattern):
            let regex: NSRegularExpression
            do {
                regex = try NSRegularExpression(pattern: pattern)
            } catch {
                throw Failure.invalid_pattern(pattern)
            }
            if let empty = regex.firstMatch(
                in: "", options: [.anchored], range: NSRange(location: 0, length: 0)
            ), empty.range.length == 0 {
                throw Failure.invalid_pattern(pattern)
            }
            matcher = .regular(regex)
        }
        rules.append(.init(kind: kind, matcher: matcher,
                           priority: priority, order: rules.count))
    }

    private static func collectExtra(
        _ expression: Grammar.Expression,
        terminals: inout Set<String>,
        patterns: inout [Grammar.Pattern]
    ) throws {
        switch expression {
        case .symbol(.terminal(let name)):
            terminals.insert(name)
        case .literal(let text):
            patterns.append(.literal(text))
        case .pattern(let pattern):
            patterns.append(.regex(pattern))
        case .choice(let children):
            for child in children {
                try collectExtra(child, terminals: &terminals, patterns: &patterns)
            }
        default:
            throw Failure.unsupported_extra
        }
    }

    private static func collectInline(
        _ expression: Grammar.Expression,
        seen: inout Set<String>,
        into rules: inout [Rule]
    ) throws {
        switch expression {
        case .literal(let value):
            if seen.insert("literal:\(value)").inserted {
                try append(.literal(value), kind: .terminal("@literal:\(value)"),
                           priority: 0, to: &rules)
            }
        case .pattern(let pattern):
            if seen.insert("pattern:\(pattern)").inserted {
                try append(.regex(pattern), kind: .terminal("@pattern:\(pattern)"),
                           priority: 0, to: &rules)
            }
        case .sequence(let children), .choice(let children):
            for child in children { try collectInline(child, seen: &seen, into: &rules) }
        case .optional(let child), .repeat0(let child), .repeat1(let child),
             .field(_, let child), .precedence(_, _, let child):
            try collectInline(child, seen: &seen, into: &rules)
        default:
            break
        }
    }

    private static func referencesTerminal(_ expression: Grammar.Expression, named name: String) -> Bool {
        switch expression {
        case .symbol(.terminal(let found)):
            return found == name
        case .sequence(let children), .choice(let children):
            return children.contains { referencesTerminal($0, named: name) }
        case .optional(let child), .repeat0(let child), .repeat1(let child),
             .field(_, let child), .precedence(_, _, let child):
            return referencesTerminal(child, named: name)
        default:
            return false
        }
    }
}
