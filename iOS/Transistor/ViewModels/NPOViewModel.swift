import Foundation

@MainActor
class NPOViewModel: ObservableObject {
    @Published var channels: [NPOChannel] = []
    @Published var programs: [NPOProgram] = []
    @Published var broadcasts: [NPOBroadcast] = []
    @Published var items: [NPOItem] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = NPOAPIService.shared
    private let mockDataService = NPODataService.shared
    private let dbService = DatabaseService.shared

    // MARK: - Load Channels

    func loadChannels() {
        channels = mockDataService.getAllChannels()
    }

    // MARK: - Load Programs

    func loadPrograms(forChannel channelId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to fetch from API first
            programs = try await apiService.fetchPrograms(forChannel: channelId)

            // Save to database
            for _ in programs {
                // Save program logic here if needed
            }
        } catch {
            // Fallback to mock data
            print("API Error: \(error.localizedDescription)")
            programs = mockDataService.getProgramsForChannel(channelId)
            errorMessage = "Using offline data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load Broadcasts

    func loadBroadcasts(forProgram programId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to fetch from API first
            broadcasts = try await apiService.fetchBroadcasts(forProgram: programId)

            // Save to database
            for broadcast in broadcasts {
                dbService.saveBroadcast(broadcast)
            }
        } catch {
            // Fallback to mock data
            print("API Error: \(error.localizedDescription)")
            broadcasts = mockDataService.getBroadcastsForProgram(programId)
            errorMessage = "Using offline data"
        }

        isLoading = false
    }

    // MARK: - Load Items

    func loadItems(forBroadcast broadcastId: String) {
        items = mockDataService.getItemsForBroadcast(broadcastId)
    }

    // MARK: - Search

    func searchPrograms(_ query: String) async {
        guard !query.isEmpty else {
            programs = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            programs = try await apiService.searchPrograms(query)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load All Programs (for Discover)

    func loadAllPrograms() async {
        isLoading = true
        errorMessage = nil

        do {
            programs = try await apiService.fetchAllPrograms()
        } catch {
            errorMessage = "Failed to load programs"
        }

        isLoading = false
    }
}
