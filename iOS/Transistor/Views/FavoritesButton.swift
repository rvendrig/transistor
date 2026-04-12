import SwiftUI

struct FavoritesButton: View {
    @ObservedObject var viewModel: NPOViewModel
    let broadcastId: String
    let itemType: String?
    let programId: String?

    var isFavorited: Bool {
        viewModel.isBroadcastFavorited(broadcastId)
    }

    var body: some View {
        Button(action: {
            viewModel.toggleFavorite(broadcastId: broadcastId, itemType: itemType, programId: programId)
        }) {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .foregroundColor(isFavorited ? .red : .gray)
        }
    }
}

#Preview {
    let viewModel = NPOViewModel()
    FavoritesButton(viewModel: viewModel, broadcastId: "test-id", itemType: "broadcast", programId: nil)
}
