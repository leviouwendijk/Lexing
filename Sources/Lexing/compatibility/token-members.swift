public extension Token {
    // Compatibility alias for external clients.
    @available(*, deprecated, renamed: "samecase(as:)")
    func sameCase(as other: Self) -> Bool { samecase(as: other) }
}
