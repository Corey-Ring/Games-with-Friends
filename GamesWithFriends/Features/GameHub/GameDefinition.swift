import SwiftUI

/// Protocol that all games must conform to for display in the GameHub
protocol GameDefinition {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconName: String { get }
    var accentColor: Color { get }
    
    /// Creates and returns the root view for this game
    func makeRootView() -> AnyView
}

/// Type-erased wrapper for GameDefinition to use in collections
struct AnyGameDefinition: GameDefinition, Identifiable {
    private let _game: any GameDefinition
    
    init(_ game: any GameDefinition) {
        self._game = game
    }
    
    var id: String { _game.id }
    var name: String { _game.name }
    var description: String { _game.description }
    var iconName: String { _game.iconName }
    var accentColor: Color { _game.accentColor }
    
    func makeRootView() -> AnyView {
        _game.makeRootView()
    }
}

