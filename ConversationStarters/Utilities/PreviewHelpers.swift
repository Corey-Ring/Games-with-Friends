import SwiftUI

#if DEBUG
extension GameViewModel {
    static var preview: GameViewModel {
        let vm = GameViewModel()
        vm.settings.playerCount = 4
        vm.settings.vibeLevel = 3
        vm.updateFilteredStarters()
        return vm
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(viewModel: .preview)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: .preview)
    }
}

struct SavedStartersView_Previews: PreviewProvider {
    static var previews: some View {
        SavedStartersView(viewModel: .preview)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        if let starter = ConversationStarterData.allStarters.first {
            CardView(starter: starter, isStarred: false, onStar: {})
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
#endif
