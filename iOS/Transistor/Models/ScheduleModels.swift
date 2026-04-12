import Foundation

// MARK: - Broadcast Schedule/Guide
struct BroadcastSchedule: Identifiable, Codable {
    let id: String
    let providerId: String
    let channelId: String
    let channelName: String
    let date: Date
    let items: [ScheduleItem]

    enum CodingKeys: String, CodingKey {
        case id, date, items
        case providerId = "provider_id"
        case channelId = "channel_id"
        case channelName = "channel_name"
    }

    var uniqueKey: String {
        "\(providerId):\(channelId):\(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

// MARK: - Schedule Item (Show in a specific time slot)
struct ScheduleItem: Identifiable, Codable {
    let id: String
    let broadcastId: String?
    let showId: String
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let duration: Int // in seconds
    let presenters: [String]
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, presenters, image, duration
        case broadcastId = "broadcast_id"
        case showId = "show_id"
        case startTime = "start_time"
        case endTime = "end_time"
    }

    var isCurrentlyBroadcasting: Bool {
        let now = Date()
        return startTime <= now && now < endTime
    }

    var isUpcoming: Bool {
        return startTime > Date()
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "\(start) - \(end)"
    }

    var durationString: String {
        let minutes = duration / 60
        return "\(minutes) min"
    }
}

// MARK: - Guide (Multiple schedules for different channels/providers)
struct BroadcastGuide: Codable {
    let date: Date
    let schedules: [BroadcastSchedule]

    var groupedByProvider: [String: [BroadcastSchedule]] {
        Dictionary(grouping: schedules) { $0.providerId }
    }

    var groupedByChannel: [String: [BroadcastSchedule]] {
        Dictionary(grouping: schedules) { $0.channelId }
    }

    var liveNow: [ScheduleItem] {
        schedules.flatMap { schedule in
            schedule.items.filter { $0.isCurrentlyBroadcasting }
        }
    }

    var upcomingNext: [ScheduleItem] {
        schedules.flatMap { schedule in
            schedule.items.filter { $0.isUpcoming }
        }
        .sorted { $0.startTime < $1.startTime }
        .prefix(10)
        .map { $0 }
    }
}

// MARK: - Extended ContentProvider Protocol
extension ContentProvider {
    /// Fetch schedule for a specific channel on a given date
    func fetchSchedule(forChannel channelId: String, date: Date) async throws -> BroadcastSchedule? {
        // Default implementation - providers can override
        return nil
    }

    /// Fetch guide for multiple channels
    func fetchGuide(forDate date: Date) async throws -> BroadcastGuide? {
        // Default implementation - providers can override
        return nil
    }

    /// Get currently broadcasting content
    func getLiveContent() async throws -> [ScheduleItem] {
        // Default implementation - providers can override
        return []
    }

    /// Get upcoming broadcasts for the next N hours
    func getUpcomingContent(hours: Int = 24) async throws -> [ScheduleItem] {
        // Default implementation - providers can override
        return []
    }
}
