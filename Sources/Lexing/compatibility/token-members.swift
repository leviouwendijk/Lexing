public extension Token {
    // Compatibility alias. Deprecate after warnings-as-errors consumers migrate.
    func sameCase(as other: Self) -> Bool { samecase(as: other) }
}
