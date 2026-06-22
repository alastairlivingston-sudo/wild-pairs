import Testing
import Foundation
@testable import WildPairsCore

// MARK: - CardColour

@Suite("CardColour")
struct CardColourTests {

    @Test("Has exactly four cases")
    func testFourCases() {
        #expect(CardColour.allCases.count == 4)
    }

    @Test("Canonical raw values")
    func testCanonicalRawValues() {
        #expect(CardColour.crimson.rawValue == "crimson")
        #expect(CardColour.cobalt.rawValue  == "cobalt")
        #expect(CardColour.jade.rawValue    == "jade")
        #expect(CardColour.amber.rawValue   == "amber")
    }

    @Test("Codable round-trip for all cases")
    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for colour in CardColour.allCases {
            let data = try encoder.encode(colour)
            let decoded = try decoder.decode(CardColour.self, from: data)
            #expect(decoded == colour)
        }
    }

    @Test("Equatable distinguishes cases")
    func testEquatable() {
        #expect(CardColour.crimson == CardColour.crimson)
        #expect(CardColour.crimson != CardColour.cobalt)
        #expect(CardColour.jade    != CardColour.amber)
    }

    @Test("No wild case in allCases")
    func testNoWildCase() {
        let rawValues = CardColour.allCases.map(\.rawValue)
        #expect(!rawValues.contains("wild"))
    }
}

// MARK: - CardType

@Suite("CardType")
struct CardTypeTests {

    @Test("number(Int) carries its associated value")
    func testNumberAssociatedValue() {
        if case .number(let v) = CardType.number(7) {
            #expect(v == 7)
        } else {
            Issue.record("Expected CardType.number(7) but pattern did not match")
        }
    }

    @Test("Codable round-trip for number card")
    func testNumberCardRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let original: CardType = .number(5)
        let decoded = try decoder.decode(CardType.self, from: try encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("Codable round-trip for all non-number cases")
    func testNonNumberCasesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let cases: [CardType] = [
            .skip, .reverse, .drawTwo, .drawFour, .changeColour,
            .discardAll, .targetedDraw, .forcedSwap, .skipTwo, .teamPlay
        ]
        for type_ in cases {
            let decoded = try decoder.decode(CardType.self, from: try encoder.encode(type_))
            #expect(decoded == type_)
        }
    }

    @Test("Equatable distinguishes number values")
    func testEquatableNumbers() {
        #expect(CardType.number(3) == CardType.number(3))
        #expect(CardType.number(3) != CardType.number(5))
    }

    @Test("Equatable distinguishes different non-number cases")
    func testEquatableNonNumber() {
        #expect(CardType.skip    == CardType.skip)
        #expect(CardType.skip    != CardType.reverse)
        #expect(CardType.drawTwo != CardType.drawFour)
    }

    @Test("Equatable distinguishes number from non-number case")
    func testEquatableNumberVsNonNumber() {
        #expect(CardType.number(0) != CardType.skip)
    }
}

// MARK: - Card

@Suite("Card")
struct CardTests {

    @Test("Coloured card Codable round-trip preserves all fields")
    func testColouredCardRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let card = Card(type: .number(5), colour: .cobalt)
        let decoded = try decoder.decode(Card.self, from: try encoder.encode(card))
        #expect(decoded == card)
    }

    @Test("Wild card Codable round-trip preserves nil colour")
    func testWildCardRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let card = Card(type: .changeColour, colour: nil)
        let decoded = try decoder.decode(Card.self, from: try encoder.encode(card))
        #expect(decoded == card)
    }

    @Test("isWild is true when colour is nil")
    func testIsWildNilColour() {
        let wild = Card(type: .drawFour, colour: nil)
        #expect(wild.isWild)
    }

    @Test("isWild is false when colour is non-nil")
    func testIsWildNonNilColour() {
        let coloured = Card(type: .skip, colour: .jade)
        #expect(!coloured.isWild)
    }

    @Test("Wild-type cards have nil colour per spec (changeColour, drawFour, discardAll)")
    func testSpecWildTypeCardsHaveNilColour() {
        let cc = Card(type: .changeColour, colour: nil)
        let df = Card(type: .drawFour,     colour: nil)
        let da = Card(type: .discardAll,   colour: nil)
        #expect(cc.isWild)
        #expect(df.isWild)
        #expect(da.isWild)
    }

    @Test("forcedSwap is a coloured action card (not wild)")
    func testForcedSwapIsColoured() {
        let fs = Card(type: .forcedSwap, colour: .crimson)
        #expect(!fs.isWild)
        #expect(fs.colour == .crimson)
    }

    @Test("Equatable uses id, type, and colour")
    func testEquatable() {
        let id = UUID()
        let a = Card(id: id, type: .number(5), colour: .crimson)
        let b = Card(id: id, type: .number(5), colour: .crimson)
        let c = Card(id: id, type: .number(6), colour: .crimson)
        let d = Card(id: id, type: .number(5), colour: .cobalt)
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)
    }

    @Test("Different UUIDs make cards unequal even with same type and colour")
    func testDifferentIDs() {
        let a = Card(type: .skip, colour: .amber)
        let b = Card(type: .skip, colour: .amber)
        #expect(a != b)
    }

    @Test("Identifiable — id is preserved through Codable round-trip")
    func testIdentifiableId() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let id = UUID()
        let card = Card(id: id, type: .reverse, colour: .amber)
        let decoded = try decoder.decode(Card.self, from: try encoder.encode(card))
        #expect(decoded.id == id)
    }
}
