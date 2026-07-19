import Foundation
import CoreLocation

struct MHMUser: Codable, Identifiable, Equatable {
    let id: Int
    let displayName: String
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
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
