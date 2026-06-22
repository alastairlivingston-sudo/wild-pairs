import Foundation

// MARK: - SeededRNG

/// A deterministic pseudo-random number generator based on the splitmix64 algorithm.
///
/// `SeededRNG` conforms to `RandomNumberGenerator` so it can be passed directly
/// to Swift standard library shuffle, random, and sampling functions.
///
/// ## Determinism Guarantee
///
/// Given the same seed, `SeededRNG` will always produce the same sequence of
/// values. This means:
/// - Tests that shuffle a deck will always get the same shuffle.
/// - AI choices that use `randomElement(using:)` are always reproducible.
/// - Saved games can resume with identical random draws by restoring the seed
///   and fast-forwarding the generator by the number of prior uses.
///
/// ## Algorithm
///
/// Splitmix64 is the default generator in Java 8's `SplittableRandom` and is
/// widely used in game development. It has a period of 2^64, excellent
/// statistical properties, and a single 64-bit state that serialises trivially.
///
/// Reference: Guy Steele et al., "Fast splittable pseudorandom number generators".
///
/// ## Usage
///
/// **In production:** The seed is generated once from `SystemRandomNumberGenerator`
/// at game start and stored in `GameState.rngSeed`.
///
/// **In tests:** Construct with a fixed seed, e.g., `SeededRNG(seed: 42)`.
///
/// ```swift
/// var rng = SeededRNG(seed: 42)
/// var cards = deck
/// cards.shuffle(using: &rng)
/// let drawn = cards.randomElement(using: &rng)
/// ```
public struct SeededRNG: RandomNumberGenerator, Sendable {

    // MARK: State

    /// The single 64-bit internal state. Advanced on every call to `next()`.
    private var state: UInt64

    // MARK: Initialiser

    /// Creates a seeded generator with the given 64-bit seed.
    ///
    /// - Parameter seed: Any `UInt64` value. Different seeds produce independent sequences.
    public init(seed: UInt64) {
        // Mix the seed so that seed 0 produces a non-degenerate sequence.
        // splitmix64 fixed point at 0 is avoided by adding the Fibonacci hash constant before first use.
        self.state = seed &+ 0x9e3779b97f4a7c15
        _ = next()
    }

    // MARK: RandomNumberGenerator

    /// Returns the next 64-bit pseudo-random value and advances the internal state.
    ///
    /// This is the only method required by `RandomNumberGenerator`. All other
    /// Swift standard library random APIs delegate to this method.
    public mutating func next() -> UInt64 {
        // Splitmix64 increment and mix
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }

    // MARK: Convenience

    /// Advances the generator by `count` steps without using the values.
    ///
    /// Used to restore the RNG to the correct position after loading a snapshot.
    /// The ViewModel calls this after restoring `GameState` to ensure subsequent
    /// draws match what would have been drawn had the game continued uninterrupted.
    ///
    /// - Parameter count: Number of `next()` calls to fast-forward through.
    public mutating func advance(by count: Int) {
        for _ in 0..<count {
            _ = next()
        }
    }

    // MARK: Seed Generation

    /// Generates a random seed using the system's cryptographic RNG.
    ///
    /// Call this once at game start when no fixed seed is provided.
    ///
    /// - Returns: A `UInt64` suitable for use as a `SeededRNG` seed.
    public static func generateSeed() -> UInt64 {
        var systemRNG = SystemRandomNumberGenerator()
        return systemRNG.next()
    }
}
