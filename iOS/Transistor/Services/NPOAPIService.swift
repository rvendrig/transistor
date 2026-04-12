import Foundation

class NPOAPIService {
    static let shared = NPOAPIService()

    // NPO API Endpoints
    private let baseURL = "https://www.nporadio.nl/api/v3"
    private let session = URLSession.shared

    // MARK: - Fetch Programs

    func fetchPrograms(forChannel channelId: String) async throws -> [NPOProgram] {
        let endpoint = "\(baseURL)/channels/\(channelId)/programs"

        guard let url = URL(string: endpoint) else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let programsResponse = try decoder.decode(ProgramsResponse.self, from: data)
            return programsResponse.programs
        } catch {
            throw NPOAPIError.decodingError(error)
        }
    }

    // MARK: - Fetch Broadcasts

    func fetchBroadcasts(forProgram programId: String, limit: Int = 50) async throws -> [NPOBroadcast] {
        let endpoint = "\(baseURL)/programs/\(programId)/broadcasts?limit=\(limit)"

        guard let url = URL(string: endpoint) else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let broadcastsResponse = try decoder.decode(BroadcastsResponse.self, from: data)
            return broadcastsResponse.broadcasts
        } catch {
            throw NPOAPIError.decodingError(error)
        }
    }

    // MARK: - Search

    func searchPrograms(_ query: String) async throws -> [NPOProgram] {
        let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "\(baseURL)/search/programs?query=\(searchQuery)"

        guard let url = URL(string: endpoint) else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            return searchResponse.results
        } catch {
            throw NPOAPIError.decodingError(error)
        }
    }

    // MARK: - Fetch All Programs (for Discover)

    func fetchAllPrograms() async throws -> [NPOProgram] {
        var allPrograms: [NPOProgram] = []
        let channels = NPODataService.shared.getAllChannels()

        for channel in channels {
            do {
                let programs = try await fetchPrograms(forChannel: channel.id)
                allPrograms.append(contentsOf: programs)
            } catch {
                print("Error fetching programs for channel \(channel.id): \(error)")
                // Continue with other channels
            }
        }

        return allPrograms
    }
}

// MARK: - API Responses

struct ProgramsResponse: Codable {
    let programs: [NPOProgram]
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case programs
        case total
    }
}

struct BroadcastsResponse: Codable {
    let broadcasts: [NPOBroadcast]
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case broadcasts
        case total
    }
}

struct SearchResponse: Codable {
    let results: [NPOProgram]
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case results
        case total
    }
}

// MARK: - Error Handling

enum NPOAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}
