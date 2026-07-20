import Foundation
import CoreLocation

struct MHMUser: Codable, Identifiable, Equatable {
    let id: Int
    let displayName: String
    let email: String?
    let avatar: URL?
    let roles: [String]?
    let phone: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case avatar
        case roles
        case phone
        case bio
    }
}

struct MHMCoordinate: Codable, Equatable {
    let lat: Double
    let lng: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct MHMHazard: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let type: String?
    let severity: String?
    let coordinate: MHMCoordinate
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, type, severity, coordinate
        case updatedAt = "updated_at"
    }
}

struct MHMCheckin: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let note: String?
    let coordinate: MHMCoordinate
    let media: [MHMMedia]
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, note, coordinate, media
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MHMMedia: Codable, Identifiable, Equatable {
    let id: Int
    let url: URL?
    let thumb: URL?
}

struct MHMJourneyPoint: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let lat: Double
    let lng: Double
    let timestamp: Int?
    let created: Date?
}

// MARK: - Community ping (mhm/v1/pings)
struct MHMPing: Codable, Identifiable, Equatable {
    let id: Int
    let userId: Int?
    let userName: String?
    let avatar: URL?
    let message: String?
    let type: String?
    let coordinate: MHMCoordinate
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case avatar, message, type, coordinate
        case createdAt = "created_at"
    }
}

// MARK: - Hazard report (mhm/v1/reports)
struct MHMReport: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String?
    let type: String?
    let severity: String?
    let status: String?
    let coordinate: MHMCoordinate
    let reporter: String?
    let media: [MHMMedia]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, type, severity, status, coordinate, reporter, media
        case createdAt = "created_at"
    }
}

// MARK: - Rescue team (mhm/v1/rescue-teams/nearby)
struct MHMRescueTeam: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let phone: String?
    let address: String?
    let coordinate: MHMCoordinate?
    let distanceKm: Double?
    let services: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, phone, address, coordinate, services
        case distanceKm = "distance_km"
    }
}

// MARK: - Chat thread (mhm/v1/chat/threads)
struct MHMChatThread: Codable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let lastMessage: String?
    let unread: Int?
    let updatedAt: Date?
    let participants: [MHMUser]?

    enum CodingKeys: String, CodingKey {
        case id, title, unread, participants
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
    }
}

// MARK: - Category (mhm/v1/categories)
struct MHMCategory: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let slug: String?
    let icon: String?
    let color: String?
    let count: Int?
}

struct MHMSyncPayload: Codable {
    let user: MHMUser?
    let hazards: [MHMHazard]
    let checkins: [MHMCheckin]
    let journey: [MHMJourneyPoint]
    let serverTime: Date?

    enum CodingKeys: String, CodingKey {
        case user, hazards, checkins, journey
        case serverTime = "server_time"
    }
}

struct MHMLoginResponse: Codable {
    let token: String
    let user: MHMUser
}

struct MHMCreateCheckinRequest: Codable {
    let title: String
    let note: String?
    let lat: Double
    let lng: Double
}

// Response wrapper — chấp nhận cả mảng bare `[...]` lẫn dạng `{ items: [...] }`
// để không phải sửa lại khi backend thay format.
struct MHMListEnvelope<Item: Codable>: Codable {
    let items: [Item]

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let arr = try? single.decode([Item].self) {
            self.items = arr
            return
        }
        let container = try decoder.container(keyedBy: DynamicKey.self)
        for key in ["items", "data", "results", "list", "pings", "reports", "threads", "teams", "categories"] {
            if let k = DynamicKey(stringValue: key),
               let arr = try? container.decode([Item].self, forKey: k) {
                self.items = arr
                return
            }
        }
        self.items = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(items)
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }
}
