import Foundation

// MARK: - GameSnapshot

/// The serialisable envelope written to disk when a game is saved.
///
/// `GameSnapshot` wraps `GameState` with metadata needed for versioning,
/// migration, and diagnostics. It is the unit that `JSONEncoder` and
/// `JSONDecoder` operate on — never `GameState` directly.
///
/// ## File Locations
///
/// ```
/// <Application Support>/WildPairs/saves/current.json   ← autosave slot
/// <Application Support>/WildPairs/settings.json        ← user preferences
/// ```
///
/// ## Migration
///
/// If `schemaVersion` in the decoded snapshot is less than the current
/// `GameState.schemaVersion`, migration functions are applied in sequence
/// before the state is used.
public struct GameSnapshot: Codable, Equatable, Sendable {

    // MARK: Metadata

    /// Schema version at the time the snapshot was written.
    /// Used to detect when migration is required.
    public let schemaVersion: Int

    /// The date and time when this snapshot was written.
    public let savedAt: Date

    /// The app build version string (`CFBundleShortVersionString`) at save time.
    /// Stored for diagnostics only; not used in migration logic.
    public let buildVersion: String

    // MARK: Game State

    /// The full serialised game state at the moment of saving.
    public let state: GameState

    // MARK: Initialiser

    public init(
        state: GameState,
        buildVersion: String = "0.1.0"
    ) {
        self.schemaVersion = state.schemaVersion
        self.savedAt = Date()
        self.buildVersion = buildVersion
        self.state = state
    }
}
