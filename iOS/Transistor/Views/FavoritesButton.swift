import SwiftUI

struct FavoritesButton: View {
    @ObservedObject var viewModel: ContentViewModel
    let contentId: String
    let contentType: ContentType
    let providerId: String

    var isFavorited: Bool {
        viewModel.isFavorited(contentId)
    }

    var body: some View {
        Button(action: {
            viewModel.toggleFavorite(contentId: contentId, contentType: contentType, providerId: providerId)
        }) {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .foregroundColor(isFavorited ? .red : .gray)
        }
    }
}

#Preview {
    let viewModel = ContentViewModel()
    FavoritesButton(viewModel: viewModel, contentId: "test-id", contentType: .broadcast, providerId: "npo")
}
