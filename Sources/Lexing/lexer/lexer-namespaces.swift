public extension Lexer {
    typealias Options = LexerOptions
    typealias Config = LexerConfig
    typealias Error = LexerError
    typealias ErrorStrategy = LexerErrorStrategy
    typealias Vocabulary = LexingSets

    enum Block {
        public typealias Options = BlockStringOptions
        public typealias Policy = BlockStringPolicy
        public typealias Policies = BlockPolicyTable
        public typealias State = LexStringBlockState
    }
}
