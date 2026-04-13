import SwiftUI

struct TopicCardView: View {
    let topic: BroadcastTopic
    let onPlay: (() -> Void)?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Fragment image
                if let imageUrl = topic.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.cardBg)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Topic title
                    Text(topic.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(isExpanded ? nil : 2)

                    // Guest names
                    ForEach(topic.guests, id: \.self) { guest in
                        Label(guest, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.transistorGreen)
                    }
                }

                Spacer()

                // Play button
                if topic.fragmentUrl != nil, let onPlay {
                    Button(action: onPlay) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.transistorGreen)
                            .font(.title3)
                    }
                }
            }

            // Description (expandable)
            if let description = topic.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(isExpanded ? nil : 3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(10)
    }
}

// MARK: - Topics section (reusable across views)

struct TopicsSectionView: View {
    let topics: [BroadcastTopic]
    let description: String?
    let onPlayTopic: ((BroadcastTopic, Int) -> Void)?

    var body: some View {
        if !topics.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Onderwerpen")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                    TopicCardView(topic: topic) {
                        onPlayTopic?(topic, index)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
        } else if let description, !description.isEmpty {
            // Fallback: plain text description
            VStack(alignment: .leading, spacing: 8) {
                Text("Over deze uitzending")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
        }
    }
}
