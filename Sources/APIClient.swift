import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://codex-everywhere.com/api/v1"
    private let session = URLSession.shared
    private let tz = "Asia/Calcutta"

    private init() {}

    // MARK: - Login
    func login(email: String, password: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/auth/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])

        let (data, response) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let http = response as? HTTPURLResponse else { throw APIError.httpError(-1) }

        if http.statusCode == 200 {
            guard let dataDict = json?["data"] as? [String: Any],
                  let token = dataDict["access_token"] as? String else {
                throw APIError.loginFailed("No token received")
            }
            return token
        } else {
            throw APIError.loginFailed(json?["message"] as? String ?? "Login failed")
        }
    }

    // MARK: - Endpoints
    func getAuthInfo(token: String) async throws -> UserData {
        try await doGet(path: "/auth/me", query: [.init(name: "timezone", value: tz)], token: token, as: AuthResponse.self).data
    }

    func getUsageStats(start: String, end: String, token: String) async throws -> UsageStats {
        try await doGet(path: "/usage/stats", query: [.init(name: "start_date", value: start), .init(name: "end_date", value: end), .init(name: "timezone", value: tz)], token: token, as: UsageStatsResponse.self).data
    }

    func getUsageList(start: String, end: String, page: Int = 1, pageSize: Int = 5, token: String) async throws -> UsageListData {
        try await doGet(path: "/usage", query: [
            .init(name: "page", value: "\(page)"),
            .init(name: "page_size", value: "\(pageSize)"),
            .init(name: "start_date", value: start),
            .init(name: "end_date", value: end),
            .init(name: "sort_by", value: "created_at"),
            .init(name: "sort_order", value: "desc"),
            .init(name: "timezone", value: tz)
        ], token: token, as: UsageListResponse.self).data
    }

    func getDashboardStats(token: String) async throws -> DashboardStats {
        try await doGet(path: "/usage/dashboard/stats", query: [.init(name: "timezone", value: tz)], token: token, as: DashboardStatsResponse.self).data
    }

    func getModelUsage(start: String, end: String, token: String) async throws -> [ModelUsageItem] {
        try await doGet(path: "/usage/dashboard/models", query: [.init(name: "start_date", value: start), .init(name: "end_date", value: end), .init(name: "timezone", value: tz)], token: token, as: ModelUsageResponse.self).data.models
    }

    func getPlatformQuotas(token: String) async throws -> [PlatformQuota] {
        try await doGet(path: "/user/platform-quotas", query: [.init(name: "timezone", value: tz)], token: token, as: PlatformQuotasResponse.self).data.platformQuotas
    }

    func getTrend(start: String, end: String, token: String) async throws -> [TrendDay] {
        try await doGet(path: "/usage/dashboard/trend", query: [
            .init(name: "start_date", value: start),
            .init(name: "end_date", value: end),
            .init(name: "granularity", value: "day"),
            .init(name: "timezone", value: tz)
        ], token: token, as: TrendResponse.self).data.trend
    }

    func getTodayStats(token: String) async throws -> UsageStats {
        try await getUsageStats(start: todayStr, end: todayStr, token: token)
    }

    // MARK: - Private
    private func doGet<R: Decodable>(path: String, query: [URLQueryItem], token: String, as type: R.Type) async throws -> R {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if !query.isEmpty { components.queryItems = query }

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try JSONDecoder().decode(R.self, from: data)
    }

    private var todayStr: String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    enum APIError: Error, LocalizedError {
        case httpError(Int)
        case loginFailed(String)
        var errorDescription: String? {
            switch self {
            case .httpError(let code): return "HTTP Error: \(code)"
            case .loginFailed(let msg): return msg
            }
        }
    }
}
