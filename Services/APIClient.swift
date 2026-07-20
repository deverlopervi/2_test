// MARK: - Extended endpoints (parity with website)

    /// Chi tiết profile user hiện tại: /mobile/me
    func me(token: String) async throws -> MHMUser {
        try await send(path: "mobile/me", method: "GET", token: token, body: Optional<String>.none)
    }

    /// Community ping feed: /pings
    func pings(token: String) async throws -> [MHMPing] {
        let env: MHMListEnvelope<MHMPing> = try await send(
            path: "pings", method: "GET", token: token, body: Optional<String>.none
        )
        return env.items
    }

    /// Hazard/incident reports: /reports
    func reports(token: String) async throws -> [MHMReport] {
        let env: MHMListEnvelope<MHMReport> = try await send(
            path: "reports", method: "GET", token: token, body: Optional<String>.none
        )
        return env.items
    }

    /// Nearby rescue teams: /rescue-teams/nearby?lat=..&lng=..
    func nearbyRescueTeams(token: String, coordinate: MHMCoordinate?) async throws -> [MHMRescueTeam] {
        var query: [URLQueryItem] = []
        if let c = coordinate {
            query.append(URLQueryItem(name: "lat", value: "\(c.lat)"))
            query.append(URLQueryItem(name: "lng", value: "\(c.lng)"))
        }
        let env: MHMListEnvelope<MHMRescueTeam> = try await send(
            path: "rescue-teams/nearby", method: "GET", token: token, query: query, body: Optional<String>.none
        )
        return env.items
    }

    /// Chat threads: /chat/threads
    func chatThreads(token: String) async throws -> [MHMChatThread] {
        let env: MHMListEnvelope<MHMChatThread> = try await send(
            path: "chat/threads", method: "GET", token: token, body: Optional<String>.none
        )
        return env.items
    }

    /// Hazard/checkin categories: /categories
    func categories(token: String) async throws -> [MHMCategory] {
        let env: MHMListEnvelope<MHMCategory> = try await send(
            path: "categories", method: "GET", token: token, body: Optional<String>.none
        )
        return env.items
    }
