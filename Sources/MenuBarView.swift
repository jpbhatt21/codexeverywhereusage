import SwiftUI
import AppKit
import Charts

struct MenuBarView: View {
    @EnvironmentObject var accountManager: AccountManager
    @StateObject private var vm = MenuBarViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.vertical, 6)

            if vm.email.isEmpty && !accountManager.isLoggedIn {
                LoginView().environmentObject(accountManager)
            } else {
                content
            }

            Divider().padding(.vertical, 6)
            footer
        }
        .padding(16)
        .frame(width: 380)
        .onAppear { refresh() }
        .onChange(of: accountManager.isLoggedIn) { _, _ in refresh() }
        .onChange(of: accountManager.activeAccount?.id) { _, _ in refresh() }
    }

    private func refresh() {
        guard let t = accountManager.currentToken else { return }
        Task { await vm.load(token: t) }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            balanceCard
            spendingRow
            costChart
            recentRequests
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text("Codex Everywhere").font(.headline)
                if !vm.email.isEmpty {
                    Text(vm.email).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            if vm.isRefreshing {
                ProgressView().scaleEffect(0.6)
            }

            Menu {
                ForEach(accountManager.accounts) { acct in
                    Button { switchAccount(acct) } label: {
                        HStack {
                            Text(acct.email)
                            if acct.id == accountManager.activeAccount?.id {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                }
                Divider()
                Button("Add Account…") { accountManager.logout() }
                Divider()
                Button("Logout", role: .destructive) { accountManager.logout() }
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(vm.balance < 5 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "wallet.pass.fill")
                        .font(.title3)
                        .foregroundStyle(vm.balance < 5 ? .red : .green)
                }

            VStack(alignment: .leading, spacing: 0) {
                Text("Balance").font(.caption).foregroundStyle(.secondary)
                Text(String(format: "$%.2f", vm.balance))
                    .font(.title.bold().monospacedDigit())
                    .foregroundStyle(vm.balance < 5 ? .red : .primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: vm.balance)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                metricPill("Cache", vm.cacheHitRate, color: .green)
                metricPill("Latency", String(format: "%.1fs", vm.stats.averageDurationMs / 1000), color: .orange)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
    }

    private func metricPill(_ label: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
    }

    // MARK: - Spending

    private var spendingRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spending", systemImage: "dollarsign.circle.fill")
                .font(.caption.bold()).foregroundStyle(.secondary)

            HStack(spacing: 0) {
                costCell("Today Cost", actual: vm.stats.todayActualCost, list: vm.stats.todayCost, color: .orange)
                Divider().frame(height: 48)
                tokenCell("Token Usage", today: vm.stats.todayTokens, total: vm.stats.totalTokens, color: .purple)
                Divider().frame(height: 48)
                costCell("Total Cost", actual: vm.stats.totalActualCost, list: vm.stats.totalCost, color: .green)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
        }
    }

    private func costCell(_ label: String, actual: Double, list: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(String(format: "$%.4f", actual))
                .font(.callout.bold().monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: actual)
            Text(String(format: "$%.4f", list))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .strikethrough(true, color: .secondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: list)
        }
        .frame(maxWidth: .infinity)
    }

    private func tokenCell(_ label: String, today: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(fmtTokens(today))
                .font(.callout.bold().monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: today)
            Text(fmtTokens(total))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: total)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart

    private var costChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("7-Day Spend", systemImage: "chart.bar.fill")
                .font(.caption.bold()).foregroundStyle(.secondary)

            let data = vm.sevenDayData
            Chart(data) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Cost", day.cost)
                )
                .foregroundStyle(day.cost > 0 ? Color.accentColor.gradient : Color.secondary.opacity(0.15).gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v >= 1 ? String(format: "$%.1f", v) : String(format: "$%.2f", v))
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(String.self) {
                            Text(v).font(.system(size: 9))
                        }
                    }
                }
            }
            .frame(height: 70)
        }
    }

    // MARK: - Recent

    private var recentRequests: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Last 3 Requests", systemImage: "clock.arrow.circlepath")
                .font(.caption.bold()).foregroundStyle(.secondary)

            if vm.recentItems.isEmpty {
                Text("No requests yet")
                    .font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 30)
            } else {
                ForEach(Array(vm.recentItems.prefix(3))) { item in
                    HStack(spacing: 6) {
                        Text(shortModel(item.model))
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(modelColor(item.model).opacity(0.15)))
                            .foregroundStyle(modelColor(item.model))

                        Text("\(fmtTokens(item.inputTokens))→\(fmtTokens(item.outputTokens))")
                            .font(.system(size: 10).monospacedDigit())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(String(format: "$%.4f", item.actualCost))
                            .font(.system(size: 10, weight: .bold).monospacedDigit())

                        Text(timeAgo(item.createdAt))
                            .font(.system(size: 9)).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button { refresh() } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }.buttonStyle(.bordered).controlSize(.small)

            Spacer()

            if !vm.lastUpdated.isEmpty {
                Text("Updated \(vm.lastUpdated)")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.bordered).controlSize(.small)
        }
    }

    // MARK: - Helpers

    private func fmtTokens(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    private func shortModel(_ m: String) -> String {
        m.replacingOccurrences(of: "gpt-", with: "G")
    }

    private func modelColor(_ m: String) -> Color {
        if m.contains("5.5") { return .blue }
        if m.contains("5.4") { return .purple }
        if m.contains("o3") { return .orange }
        if m.contains("o4") { return .green }
        return .accentColor
    }

    private func timeAgo(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "\(Int(diff))s" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return "\(Int(diff / 86400))d"
    }

    private func switchAccount(_ acct: Account) {
        accountManager.switchTo(acct)
        Task { await vm.load(token: acct.token) }
    }
}

// MARK: - Chart Data

struct DayCost: Identifiable {
    let id = UUID()
    let label: String
    let cost: Double
}

// MARK: - ViewModel

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var email = ""
    @Published var balance: Double = 0
    @Published var stats = DashboardStats(
        totalApiKeys: 0, activeApiKeys: 0, totalRequests: 0, totalInputTokens: 0,
        totalOutputTokens: 0, totalCacheCreationTokens: 0, totalCacheReadTokens: 0,
        totalTokens: 0, totalCost: 0, totalActualCost: 0,
        todayRequests: 0, todayInputTokens: 0, todayOutputTokens: 0,
        todayCacheCreationTokens: 0, todayCacheReadTokens: 0, todayTokens: 0,
        todayCost: 0, todayActualCost: 0, averageDurationMs: 0, rpm: 0, tpm: 0
    )
    @Published var recentItems: [UsageItem] = []
    @Published var trend: [TrendDay] = []
    @Published var lastUpdated = ""
    @Published var isRefreshing = false

    var cacheHitRate: String {
        let total = stats.todayCacheReadTokens + stats.todayInputTokens
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", Double(stats.todayCacheReadTokens) / Double(total) * 100)
    }

    var sevenDayData: [DayCost] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let dayFmt = DateFormatter(); dayFmt.dateFormat = "EEE"

        var map: [String: Double] = [:]
        for t in trend { map[t.date] = t.actualCost }

        return (0..<7).reversed().map { i in
            let d = cal.date(byAdding: .day, value: -i, to: cal.startOfDay(for: Date()))!
            let key = fmt.string(from: d)
            return DayCost(label: dayFmt.string(from: d), cost: map[key] ?? 0)
        }
    }

    private let api = APIClient.shared
    private var timer: Timer?
    private var token: String?

    init() {
        loadFromCache()
        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            guard let self, let t = self.token else { return }
            Task { @MainActor in await self.refresh(token: t) }
        }
    }

    deinit { timer?.invalidate() }

    func load(token: String? = nil) async {
        if let t = token { self.token = t }
        guard let t = token ?? self.token else { return }
        await refresh(token: t)
    }

    private func refresh(token: String) async {
        isRefreshing = true
        do {
            let today = todayStr
            let start = weekStart

            async let a = api.getAuthInfo(token: token)
            async let b = api.getDashboardStats(token: token)
            async let c = api.getUsageList(start: today, end: today, page: 1, pageSize: 10, token: token)
            async let d = api.getTrend(start: start, end: today, token: token)

            let (auth, dash, recent, trendData) = try await (a, b, c, d)

            email = auth.email
            balance = auth.balance
            stats = dash
            recentItems = recent.items
            trend = trendData

            let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
            lastUpdated = fmt.string(from: Date())
            saveToCache()
        } catch {}
        isRefreshing = false
    }

    private func loadFromCache() {
        let d = UserDefaults.standard
        email = d.string(forKey: "c_email") ?? ""
        balance = d.double(forKey: "c_balance")
        lastUpdated = d.string(forKey: "c_updated") ?? ""
        if let data = d.data(forKey: "c_stats"),
           let v = try? JSONDecoder().decode(DashboardStats.self, from: data) { stats = v }
        if let data = d.data(forKey: "c_recent"),
           let v = try? JSONDecoder().decode([UsageItem].self, from: data) { recentItems = v }
        if let data = d.data(forKey: "c_trend"),
           let v = try? JSONDecoder().decode([TrendDay].self, from: data) { trend = v }
    }

    private func saveToCache() {
        let d = UserDefaults.standard
        d.set(email, forKey: "c_email")
        d.set(balance, forKey: "c_balance")
        d.set(lastUpdated, forKey: "c_updated")
        if let data = try? JSONEncoder().encode(stats) { d.set(data, forKey: "c_stats") }
        if let data = try? JSONEncoder().encode(recentItems) { d.set(data, forKey: "c_recent") }
        if let data = try? JSONEncoder().encode(trend) { d.set(data, forKey: "c_trend") }
    }

    private var todayStr: String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private var weekStart: String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let d = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date()))!
        return fmt.string(from: d)
    }
}
