import Testing
@testable import WildPairsCore

@Suite("SeededRNG")
struct SeededRNGTests {

    @Test("Same seed produces identical sequences")
    func testDeterminism() {
        var rng1 = SeededRNG(seed: 42)
        var rng2 = SeededRNG(seed: 42)
        for _ in 0..<100 {
            #expect(rng1.next() == rng2.next())
        }
    }

    @Test("Different seeds produce different sequences")
    func testDifferentSeeds() {
        var rng1 = SeededRNG(seed: 1)
        var rng2 = SeededRNG(seed: 2)
        let seq1 = (0..<20).map { _ in rng1.next() }
        let seq2 = (0..<20).map { _ in rng2.next() }
        #expect(seq1 != seq2)
    }

    @Test("Seed 0 produces a non-zero first value (no fixed-point degeneracy)")
    func testSeedZeroIsNonDegenerate() {
        var rng = SeededRNG(seed: 0)
        #expect(rng.next() != 0)
    }

    @Test("Seed 0 produces a non-constant sequence")
    func testSeedZeroNonConstant() {
        var rng = SeededRNG(seed: 0)
        let first  = rng.next()
        let second = rng.next()
        #expect(first != second)
    }

    @Test("advance(by:) skips the exact number of next() calls")
    func testAdvanceBySkipsCorrectly() {
        var rng1 = SeededRNG(seed: 99)
        var rng2 = SeededRNG(seed: 99)
        rng1.advance(by: 10)
        for _ in 0..<10 { _ = rng2.next() }
        #expect(rng1.next() == rng2.next())
    }

    @Test("advance(by: 0) does not change the sequence")
    func testAdvanceByZeroIsNoop() {
        var rng1 = SeededRNG(seed: 7)
        var rng2 = SeededRNG(seed: 7)
        rng1.advance(by: 0)
        #expect(rng1.next() == rng2.next())
    }

    @Test("generateSeed returns a UInt64 (smoke test)")
    func testGenerateSeed() {
        let seed = SeededRNG.generateSeed()
        // Just verify it's a valid UInt64 — its randomness cannot be asserted deterministically.
        _ = SeededRNG(seed: seed)
    }
}
