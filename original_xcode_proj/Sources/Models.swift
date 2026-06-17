import Foundation

// MARK: - Auth
struct AuthResponse: Codable {
    let code: Int
    let message: String
    let data: UserData
}

struct UserData: Codable {
    let id: Int
    let email: String
    let username: String
    let role: String
    let balance: Double
    let concurrency: Int
    let status: String
    let totalRecharged: Int
    let rpmLimit: Int

    enum CodingKeys: String, CodingKey {
        case id, email, username, role, balance, concurrency, status
        case totalRecharged = "total_recharged"
        case rpmLimit = "rpm_limit"
    }
}

// MARK: - Usage Stats
struct UsageStatsResponse: Codable {
    let code: Int
    let data: UsageStats
}

struct UsageStats: Codable {
    let totalRequests: Int
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let totalActualCost: Double
    let averageDurationMs: Double

    enum CodingKeys: String, CodingKey {
        case totalRequests = "total_requests"
        case totalInputTokens = "total_input_tokens"
        case totalOutputTokens = "total_output_tokens"
        case totalCacheTokens = "total_cache_tokens"
        case totalTokens = "total_tokens"
        case totalCost = "total_cost"
        case totalActualCost = "total_actual_cost"
        case averageDurationMs = "average_duration_ms"
    }
}

// MARK: - Usage List
struct UsageListResponse: Codable {
    let code: Int
    let data: UsageListData
}

struct UsageListData: Codable {
    let items: [UsageItem]
    let total: Int

    enum CodingKeys: String, CodingKey {
        case items, total
    }
}

struct UsageItem: Codable, Identifiable {
    let id: Int
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let totalCost: Double
    let actualCost: Double
    let durationMs: Int
    let firstTokenMs: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, model
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case totalCost = "total_cost"
        case actualCost = "actual_cost"
        case durationMs = "duration_ms"
        case firstTokenMs = "first_token_ms"
        case createdAt = "created_at"
    }
}

// MARK: - Dashboard Stats
struct DashboardStatsResponse: Codable {
    let code: Int
    let data: DashboardStats
}

struct DashboardStats: Codable {
    let totalApiKeys: Int
    let activeApiKeys: Int
    let totalRequests: Int
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheCreationTokens: Int
    let totalCacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let totalActualCost: Double
    let todayRequests: Int
    let todayInputTokens: Int
    let todayOutputTokens: Int
    let todayCacheCreationTokens: Int
    let todayCacheReadTokens: Int
    let todayTokens: Int
    let todayCost: Double
    let todayActualCost: Double
    let averageDurationMs: Double
    let rpm: Int
    let tpm: Int
    let byPlatform: [DashboardPlatformStats]

    init(
        totalApiKeys: Int,
        activeApiKeys: Int,
        totalRequests: Int,
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalCacheCreationTokens: Int,
        totalCacheReadTokens: Int,
        totalTokens: Int,
        totalCost: Double,
        totalActualCost: Double,
        todayRequests: Int,
        todayInputTokens: Int,
        todayOutputTokens: Int,
        todayCacheCreationTokens: Int,
        todayCacheReadTokens: Int,
        todayTokens: Int,
        todayCost: Double,
        todayActualCost: Double,
        averageDurationMs: Double,
        rpm: Int,
        tpm: Int,
        byPlatform: [DashboardPlatformStats] = []
    ) {
        self.totalApiKeys = totalApiKeys
        self.activeApiKeys = activeApiKeys
        self.totalRequests = totalRequests
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCacheCreationTokens = totalCacheCreationTokens
        self.totalCacheReadTokens = totalCacheReadTokens
        self.totalTokens = totalTokens
        self.totalCost = totalCost
        self.totalActualCost = totalActualCost
        self.todayRequests = todayRequests
        self.todayInputTokens = todayInputTokens
        self.todayOutputTokens = todayOutputTokens
        self.todayCacheCreationTokens = todayCacheCreationTokens
        self.todayCacheReadTokens = todayCacheReadTokens
        self.todayTokens = todayTokens
        self.todayCost = todayCost
        self.todayActualCost = todayActualCost
        self.averageDurationMs = averageDurationMs
        self.rpm = rpm
        self.tpm = tpm
        self.byPlatform = byPlatform
    }

    enum CodingKeys: String, CodingKey {
        case totalApiKeys = "total_api_keys"
        case activeApiKeys = "active_api_keys"
        case totalRequests = "total_requests"
        case totalInputTokens = "total_input_tokens"
        case totalOutputTokens = "total_output_tokens"
        case totalCacheCreationTokens = "total_cache_creation_tokens"
        case totalCacheReadTokens = "total_cache_read_tokens"
        case totalTokens = "total_tokens"
        case totalCost = "total_cost"
        case totalActualCost = "total_actual_cost"
        case todayRequests = "today_requests"
        case todayInputTokens = "today_input_tokens"
        case todayOutputTokens = "today_output_tokens"
        case todayCacheCreationTokens = "today_cache_creation_tokens"
        case todayCacheReadTokens = "today_cache_read_tokens"
        case todayTokens = "today_tokens"
        case todayCost = "today_cost"
        case todayActualCost = "today_actual_cost"
        case averageDurationMs = "average_duration_ms"
        case rpm, tpm
        case byPlatform = "by_platform"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            totalApiKeys: try c.decode(Int.self, forKey: .totalApiKeys),
            activeApiKeys: try c.decode(Int.self, forKey: .activeApiKeys),
            totalRequests: try c.decode(Int.self, forKey: .totalRequests),
            totalInputTokens: try c.decode(Int.self, forKey: .totalInputTokens),
            totalOutputTokens: try c.decode(Int.self, forKey: .totalOutputTokens),
            totalCacheCreationTokens: try c.decode(Int.self, forKey: .totalCacheCreationTokens),
            totalCacheReadTokens: try c.decode(Int.self, forKey: .totalCacheReadTokens),
            totalTokens: try c.decode(Int.self, forKey: .totalTokens),
            totalCost: try c.decode(Double.self, forKey: .totalCost),
            totalActualCost: try c.decode(Double.self, forKey: .totalActualCost),
            todayRequests: try c.decode(Int.self, forKey: .todayRequests),
            todayInputTokens: try c.decode(Int.self, forKey: .todayInputTokens),
            todayOutputTokens: try c.decode(Int.self, forKey: .todayOutputTokens),
            todayCacheCreationTokens: try c.decode(Int.self, forKey: .todayCacheCreationTokens),
            todayCacheReadTokens: try c.decode(Int.self, forKey: .todayCacheReadTokens),
            todayTokens: try c.decode(Int.self, forKey: .todayTokens),
            todayCost: try c.decode(Double.self, forKey: .todayCost),
            todayActualCost: try c.decode(Double.self, forKey: .todayActualCost),
            averageDurationMs: try c.decode(Double.self, forKey: .averageDurationMs),
            rpm: try c.decode(Int.self, forKey: .rpm),
            tpm: try c.decode(Int.self, forKey: .tpm),
            byPlatform: try c.decodeIfPresent([DashboardPlatformStats].self, forKey: .byPlatform) ?? []
        )
    }
}

struct DashboardPlatformStats: Codable, Identifiable {
    var id: String { platform }
    let platform: String
    let totalRequests: Int
    let totalTokens: Int
    let totalActualCost: Double
    let todayRequests: Int
    let todayTokens: Int
    let todayActualCost: Double

    enum CodingKeys: String, CodingKey {
        case platform
        case totalRequests = "total_requests"
        case totalTokens = "total_tokens"
        case totalActualCost = "total_actual_cost"
        case todayRequests = "today_requests"
        case todayTokens = "today_tokens"
        case todayActualCost = "today_actual_cost"
    }
}

// MARK: - Model Usage
struct ModelUsageResponse: Codable {
    let code: Int
    let data: ModelUsageData
}

struct ModelUsageData: Codable {
    let models: [ModelUsageItem]
    let startDate: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case models
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct ModelUsageItem: Codable, Identifiable {
    var id: String { model }
    let model: String
    let requests: Int
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let cost: Double
    let actualCost: Double

    enum CodingKeys: String, CodingKey {
        case model, requests, cost
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case totalTokens = "total_tokens"
        case actualCost = "actual_cost"
    }
}

// MARK: - Platform Quotas
struct PlatformQuotasResponse: Codable {
    let code: Int
    let data: PlatformQuotasData
}

struct PlatformQuotasData: Codable {
    let platformQuotas: [PlatformQuota]

    enum CodingKeys: String, CodingKey {
        case platformQuotas = "platform_quotas"
    }
}

struct PlatformQuota: Codable, Identifiable {
    var id: String { platform }
    let platform: String
    let dailyLimitUsd: Double?
    let dailyUsageUsd: Double
    let weeklyLimitUsd: Double?
    let weeklyUsageUsd: Double
    let monthlyLimitUsd: Double?
    let monthlyUsageUsd: Double

    enum CodingKeys: String, CodingKey {
        case platform
        case dailyLimitUsd = "daily_limit_usd"
        case dailyUsageUsd = "daily_usage_usd"
        case weeklyLimitUsd = "weekly_limit_usd"
        case weeklyUsageUsd = "weekly_usage_usd"
        case monthlyLimitUsd = "monthly_limit_usd"
        case monthlyUsageUsd = "monthly_usage_usd"
    }
}

// MARK: - Trend
struct TrendResponse: Codable {
    let code: Int
    let data: TrendData
}

struct TrendData: Codable {
    let trend: [TrendDay]
    let startDate: String
    let endDate: String
    let granularity: String

    enum CodingKeys: String, CodingKey {
        case trend, granularity
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct TrendDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let requests: Int
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let cost: Double
    let actualCost: Double

    enum CodingKeys: String, CodingKey {
        case date, requests, cost
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case totalTokens = "total_tokens"
        case actualCost = "actual_cost"
    }
}
