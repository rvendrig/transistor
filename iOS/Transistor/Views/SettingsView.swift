import SwiftUI

struct SettingsView: View {
    @ObservedObject private var providerStore = ProviderStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Providers").foregroundColor(.white)) {
                    ForEach(Array(providerStore.providers.values), id: \.id) { provider in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(provider.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(provider.type.rawValue.replacingOccurrences(of: "_", with: " "))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { providerStore.activeProviders.contains(provider.id) },
                                set: { providerStore.setProviderActive(provider.id, $0) }
                            ))
                            .tint(.transistorGreen)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Over").foregroundColor(.white)) {
                    HStack {
                        Text("Versie")
                            .foregroundColor(.white)
                        Spacer()
                        Text("0.1.0")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Datamodel")
                            .foregroundColor(.white)
                        Spacer()
                        Text("Provider-agnostisch")
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Data").foregroundColor(.white)) {
                    Button(action: {
                        // TODO: clear cache
                    }) {
                        Text("Cache wissen")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Instellingen")
            .background(Color.darkBg)
        }
    }
}
