import Foundation

// MARK: - PersistenceError

public enum PersistenceError: Error, Equatable {
    case noSavedGame
    case decodingError(String)
    case encodingError(String)
    case writeError(String)
}
