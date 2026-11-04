import Foundation

public extension Lexer {
    /// Checked lexical configuration. Grammar.Language remains the grammar IR;
    /// this specification only configures a concrete lexer implementation.
    struct Specification: Sendable {
        public enum Failure: Swift.Error, Equatable, Sendable {
            case conflicting_identifier(String)
            case missing_block_policy(String)
            case unsupported_delimiter(String)
            case invalid_comment_signature
            case ambiguous_comment_signature(String)
            case requires_lossless_emission
        }

        public let vocabulary: Lexer.Vocabulary
        public let options: Lexer.Options
        public let config: Lexer.Config

        public init(
            vocabulary: Lexer.Vocabulary,
            options: Lexer.Options = .lossless,
            config: Lexer.Config = .init(),
            recognize_dates: Bool = false
        ) throws {
            let conflicting = vocabulary.idents.intersection(
                vocabulary.keywords.union(vocabulary.stringBlockKeywords)
            )
            if let name = conflicting.sorted().first {
                throw Failure.conflicting_identifier(name)
            }
            for keyword in vocabulary.stringBlockKeywords.sorted() {
                guard options.block.policies.predetermined[keyword] != nil else {
                    throw Failure.missing_block_policy(keyword)
                }
            }
            for policy in options.block.policies.predetermined.values {
                try Self.check(policy.delimiter)
            }
            try Self.check(options.block.policies.fallback.delimiter)

            var prefixes: [String] = []
            for signature in options.comments {
                let prefix: String
                switch signature {
                case .line(let value):
                    prefix = value
                case .block(let start, let end, _):
                    guard !end.isEmpty else { throw Failure.invalid_comment_signature }
                    prefix = start
                }
                guard !prefix.isEmpty else { throw Failure.invalid_comment_signature }
                for prior in prefixes where prior.hasPrefix(prefix) || prefix.hasPrefix(prior) {
                    throw Failure.ambiguous_comment_signature(prefix)
                }
                prefixes.append(prefix)
            }
            guard options.emit.whitespace, options.emit.newlines,
                  options.emit.comments else { throw Failure.requires_lossless_emission }
            switch options.unsupported {
            case .error_token: break
            case .skip: throw Failure.requires_lossless_emission
            }
            var configured = options
            configured.recognize_dates = recognize_dates
            self.vocabulary = vocabulary
            self.options = configured
            self.config = config
        }

        public func lex(_ source: String) throws -> LexingResult {
            try LexingResult.collect(
                source: source, sets: vocabulary, options: options, config: config
            )
        }

        private static func check(_ delimiter: Delimiter) throws {
            let supported: Set<String> = ["{", "[", "(", "<"]
            let endings: [String: String] = ["{": "}", "[": "]", "(": ")", "<": ">"]
            guard supported.contains(delimiter.start),
                  endings[delimiter.start] == delimiter.end else {
                throw Failure.unsupported_delimiter(delimiter.start)
            }
        }
    }
}
