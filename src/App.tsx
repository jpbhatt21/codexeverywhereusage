import { invoke } from "@tauri-apps/api/core";
import { BarChart3, Brain, Check, Clock3, DollarSign, LogOut, Plus, ArrowUpRight, RefreshCw, Wallet, X, ArrowDownIcon, ArrowUpIcon } from "lucide-react";
import { openUrl } from "@tauri-apps/plugin-opener";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Bar, BarChart, CartesianGrid, LabelList, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { AccountAvatar, pickAvatarColor } from "./components/avatar";
import Login from "./Login";
import { readAccounts, readActiveAccount, readDashboardCache, readCurrencyPreference, readExchangeRateCache, saveAccounts, saveActiveAccount, saveDashboardCache, saveCurrencyPreference, saveExchangeRateCache, removeAccount } from "./utils/storage";
import type { Account, DashboardData, UpdateInfo } from "./types";
import { resizeManager } from "./utils/window";
import { init } from "./utils/init";
import Update from "./Update";

const currencies = ["USD", "EUR", "GBP", "INR", "JPY", "CAD", "AUD", "SGD", "CHF"] as const;
const rateMaxAge = 24 * 60 * 60 * 1000;
let initd = false;
const emptyDashboard: DashboardData = {
	email: "",
	balance: 0,
	stats: {
		total_api_keys: 0,
		active_api_keys: 0,
		total_requests: 0,
		total_input_tokens: 0,
		total_output_tokens: 0,
		total_cache_creation_tokens: 0,
		total_cache_read_tokens: 0,
		total_tokens: 0,
		total_cost: 0,
		total_actual_cost: 0,
		today_requests: 0,
		today_input_tokens: 0,
		today_output_tokens: 0,
		today_cache_creation_tokens: 0,
		today_cache_read_tokens: 0,
		today_tokens: 0,
		today_cost: 0,
		today_actual_cost: 0,
		average_duration_ms: 0,
		rpm: 0,
		tpm: 0,
	},
	recentItems: [],
	trend: [],
	lastUpdated: "",
};

function money(value: number, currency = "USD", rate = 1, digits = 4) {
	return new Intl.NumberFormat(undefined, {
		style: "currency",
		currency,
		minimumFractionDigits: digits,
		maximumFractionDigits: digits,
	}).format(value * rate);
}

function roundedMoney(value: number, currency = "USD", rate = 1) {
	return new Intl.NumberFormat(undefined, {
		style: "currency",
		currency,
		maximumFractionDigits: 0,
	}).format(value * rate);
}

function tokens(value: number) {
	if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
	if (value >= 1_000) return `${(value / 1_000).toFixed(1)}K`;
	return String(value);
}

function shortModel(model: string) {
	return model.replace("gpt-", "G");
}

function timeAgo(iso: string) {
	const date = new Date(iso);
	if (Number.isNaN(date.getTime())) return "";
	const diff = Math.max(0, Date.now() - date.getTime());
	if (diff < 60_000) return `${Math.floor(diff / 1000)}s`;
	if (diff < 3_600_000) return `${Math.floor(diff / 60_000)}m`;
	if (diff < 86_400_000) return `${Math.floor(diff / 3_600_000)}h`;
	return `${Math.floor(diff / 86_400_000)}d`;
}

function chartData(data: DashboardData) {
	const byDate = new Map(data.trend.map((day) => [day.date, day.actual_cost]));
	return Array.from({ length: 7 }, (_, index) => {
		const date = new Date();
		date.setHours(0, 0, 0, 0);
		date.setDate(date.getDate() - (6 - index));
		const key = date.toLocaleDateString("en-CA");
		return {
			label: date.toLocaleDateString(undefined, { weekday: "short" }),
			Cost: byDate.get(key) ?? 0,
		};
	});
}

function openUri(url: string) {
	console.log("Opening URL:", url);
	openUrl(url).catch((err) => console.error("Failed to open URL:", err));
}

export default function App() {
	const [accounts, setAccounts] = useState<Account[]>(() => readAccounts().map((account) => ({ ...account, avatarColor: account.avatarColor ?? pickAvatarColor(account.email) })));
	const [activeAccount, setActiveAccount] = useState<Account | null>(() => {
		const account = readActiveAccount();
		return account ? { ...account, avatarColor: account.avatarColor ?? pickAvatarColor(account.email) } : null;
	});
	const [dashboard, setDashboard] = useState<DashboardData>(() => readDashboardCache() ?? emptyDashboard);
	const [currency, setCurrency] = useState(() => readCurrencyPreference());
	const [exchangeRate, setExchangeRate] = useState(() => {
		const cached = readExchangeRateCache();
		return cached?.currency === readCurrencyPreference() ? cached.rate : 1;
	});
	const [refreshing, setRefreshing] = useState(false);
	const [updateInfo, setUpdateInfo] = useState<UpdateInfo>({
		version: "-",
		currentVersion: "",
		update: false,
		date: "",
		body: "{}",
		raw: null,
	});
	const [accountMenuOpen, setAccountMenuOpen] = useState(false);
	const [windowActive, setWindowActive] = useState(() => document.visibilityState === "visible" && document.hasFocus());
	const isLoggedIn = Boolean(activeAccount);
	const shellRef = useRef<HTMLDivElement>(null);
	const formatMoney = useCallback((value: number, digits = 4) => money(value, currency, exchangeRate, digits), [currency, exchangeRate]);
	const formatRoundedMoney = useCallback((value: number) => roundedMoney(value, currency, exchangeRate), [currency, exchangeRate]);
	const refresh = useCallback(
		async (account = activeAccount) => {
			if (!account) return;
			setRefreshing(true);
			try {
				const raw = (await invoke("load_dashboard", { token: account.token })) as {
					email: string;
					balance: number;
					stats: DashboardData["stats"];
					recent_items: DashboardData["recentItems"];
					trend: DashboardData["trend"];
				};
				const next: DashboardData = {
					email: raw.email,
					balance: raw.balance,
					stats: raw.stats,
					recentItems: raw.recent_items,
					trend: raw.trend,
					lastUpdated: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
				};
				setDashboard(next);
				saveDashboardCache(next);
			} finally {
				setRefreshing(false);
			}
		},
		[activeAccount],
	);

	useEffect(() => {
		let cancelled = false;
		const updateWindowActive = () => {
			const next = document.visibilityState === "visible" && document.hasFocus();
			setWindowActive((current) => {
				if (current === next) return current;
				if (next && !cancelled) {
					void refresh(activeAccount);
				}
				return next;
			});
		};

		const onFocus = () => updateWindowActive();
		const onBlur = () => updateWindowActive();
		const onVisibilityChange = () => updateWindowActive();

		updateWindowActive();
		window.addEventListener("focus", onFocus);
		window.addEventListener("blur", onBlur);
		document.addEventListener("visibilitychange", onVisibilityChange);

		return () => {
			cancelled = true;
			window.removeEventListener("focus", onFocus);
			window.removeEventListener("blur", onBlur);
			document.removeEventListener("visibilitychange", onVisibilityChange);
		};
	}, [activeAccount, refresh]);

	useEffect(() => {
		if (!windowActive) return;
		void refresh(activeAccount);
		const id = window.setInterval(() => void refresh(activeAccount), 120_000);
		return () => window.clearInterval(id);
	}, [activeAccount, refresh, windowActive]);

	useEffect(() => {
		saveCurrencyPreference(currency);
		if (currency === "USD") {
			setExchangeRate(1);
			saveExchangeRateCache({ currency, rate: 1, fetchedAt: Date.now() });
			return;
		}

		const cached = readExchangeRateCache();
		if (cached?.currency === currency && Date.now() - cached.fetchedAt < rateMaxAge) {
			setExchangeRate(cached.rate);
			return;
		}

		let cancelled = false;
		fetch(`https://api.frankfurter.dev/v2/rate/USD/${currency}`)
			.then((response) => {
				if (!response.ok) throw new Error(`Rate lookup failed: ${response.status}`);
				return response.json() as Promise<{ rate?: number }>;
			})
			.then((data) => {
				if (cancelled || typeof data.rate !== "number") return;
				setExchangeRate(data.rate);
				saveExchangeRateCache({ currency, rate: data.rate, fetchedAt: Date.now() });
			})
			.catch(() => {
				const fallback = readExchangeRateCache();
				if (!cancelled && fallback?.currency === currency) setExchangeRate(fallback.rate);
			});

		return () => {
			cancelled = true;
		};
	}, [currency]);

	const setActive = (account: Account | null) => {
		setActiveAccount(account);
		saveActiveAccount(account);
		setAccountMenuOpen(false);
	};

	const addAccount = (account: Account) => {
		const next = [...accounts.filter((item) => item.id !== account.id), account];
		setAccounts(next);
		saveAccounts(next);
		setActive(account);
	};

	const logout = () => {
		setActiveAccount(null);
		removeAccount(activeAccount!);
		setDashboard(emptyDashboard);
	};

	const cacheRate = useMemo(() => {
		const total = dashboard.stats.today_cache_read_tokens + dashboard.stats.today_input_tokens;
		return total > 0 ? `${Math.round((dashboard.stats.today_cache_read_tokens / total) * 100)}%` : "0%";
	}, [dashboard.stats]);

	useEffect(() => {
		if (!initd) {
			initd = true;
			(async () => {
				if (isLoggedIn || dashboard.email) {
					const info = await init();
					if (info.update) {
						setUpdateInfo(info);
						console.log(`Update available: ${info.version}`, info);
					} else {
						setUpdateInfo((prev) => ({ ...prev, currentVersion: info.currentVersion }));
						console.log("No update available");
					}
				}
			})();
		}
	}, [isLoggedIn, dashboard.email]);
	useEffect(() => {
		if (shellRef.current) {
			const interval = setInterval(() => {
				resizeManager(shellRef.current!);
			}, 100);

			return () => {
				clearInterval(interval);
			};
		}
	}, [shellRef]);
	if (!isLoggedIn && !dashboard.email) {
		return (
			<div className="flex w-full h-full items-center justify-center p-4 fixed">
				<Login accounts={accounts} onLogin={addAccount} onSwitch={setActive} updateInfo={updateInfo} />
			</div>
		);
	}
	return (
		<Shell ref={shellRef}>
			<header className="header">
				{/* do not remove this button */}
				<button className="h-0 w-0 -mr-2" />
				<button className="brand-link" onClick={() => openUri("https://codex-everywhere.com/dashboard")} aria-label="Open dashboard">
					<div className="brand-mark">
						<Brain size={22} />
					</div>
					<div className="title-block">
						<h1>Codex Everywhere</h1>
						<p>{dashboard.email || activeAccount?.email}</p>
					</div>
					<ArrowUpRight size={14} className="brand-shortcut" />
				</button>
				{refreshing && <RefreshCw className="spin muted-icon" size={16} />}
				<div className="account-menu">
					<button className="icon-button" onClick={() => setAccountMenuOpen((open) => !open)} aria-label="Accounts">
						<AccountAvatar email={activeAccount?.email ?? dashboard.email} color={activeAccount?.avatarColor ?? pickAvatarColor(activeAccount?.email ?? dashboard.email ?? "")} />
					</button>
					{accountMenuOpen && (
						<div className="menu popups">
							{accounts.map((account) => (
								<button key={account.id} onClick={() => setActive(account)}>
									<span className="account-entry">
										<AccountAvatar email={account.email} color={account.avatarColor} />
										<span>{account.email}</span>
									</span>
									{activeAccount?.id === account.id && <Check size={14} />}
								</button>
							))}
							<button
								onClick={() => {
									setActive(null);
								}}>
								<Plus
									size={14}
									style={{
										marginRight: "12px",
										marginLeft: "6px",
									}}
								/>
								<span
									style={{
										width: "100%",
										translate: "-8px",
									}}>
									Add Account
								</span>
							</button>
							<button className="danger" onClick={logout}>
								<LogOut size={14} />
								Logout
							</button>
						</div>
					)}
				</div>
			</header>

			{!isLoggedIn ? (
				<Login accounts={accounts} onLogin={addAccount} onSwitch={setActive} compact updateInfo={updateInfo} />
			) : (
				<main className="content w-full min-w-fit">
					<section className="balance-card min-w-fit justify-between gap-2">
						<div className="flex gap-2 items-center justify-center">
							<div className={dashboard.balance < 5 ? "wallet low" : "wallet"}>
								<Wallet size={22} />
							</div>
							<div className="min-w-fit">
								<div className="balance-row min-w-fit">
									<p className="label">Balance</p>
									<button className="small-button topup-button" onClick={() => openUri("https://codex-everywhere.com/purchase")}>
										<ArrowUpRight size={13} />
										Top Up
									</button>
								</div>
								<div className={dashboard.balance < 5 ? "balance low-text" : "balance"}>{formatMoney(dashboard.balance, 2)}</div>
							</div>
						</div>
						<div className="metrics min-w-fit">
							<span className="min-w-fit text-start w-full flex flex-col">
								<span>Cache:</span>
								<b>{cacheRate}</b>
							</span>
							<span className="min-w-fit text-start w-full flex-col flex">
								<span>Latency:</span>
								<b>{(dashboard.stats.average_duration_ms / 1000).toFixed(1)}s</b>
							</span>
						</div>
					</section>

					<SectionTitle icon={<DollarSign size={14} />} text="Spending" />
					<section className="spend-grid min-w-fit">
						<Metric label="Today Cost" value={formatMoney(dashboard.stats.today_actual_cost)} sub={formatMoney(dashboard.stats.today_cost)} />
						<Metric label="Token Usage" value={tokens(dashboard.stats.today_tokens)} sub={tokens(dashboard.stats.total_tokens)} tone="violet" />
						<Metric label="Total Cost" value={formatMoney(dashboard.stats.total_actual_cost)} sub={formatMoney(dashboard.stats.total_cost)} tone="green" />
					</section>

					<SectionTitle icon={<BarChart3 size={14} />} text="7-Day Spend" />
					<section className="chart">
						<ResponsiveContainer width="100%" height={82}>
							<BarChart data={chartData(dashboard)} margin={{ top: 4, right: 2, left: 0, bottom: 0 }}>
								<CartesianGrid stroke="rgba(238, 242, 248, 0.12)" strokeDasharray="3 3" vertical={false} />
								<XAxis dataKey="label" tickLine={false} axisLine={false} fontSize={10} />
								<YAxis tickLine={false} axisLine={false} fontSize={10} width={58} tickFormatter={(value) => formatMoney(Number(value), 2)} />
								<Tooltip
									formatter={(value) => formatMoney(Number(value), 4)}
									cursor={{ fill: "rgba(47, 111, 237, 0.08)" }}
									contentStyle={{
										background: "var(--popup-bg)",
										border: "1px solid rgba(238, 242, 248, 0.16)",
										borderRadius: 8,
										color: "#eef2f8",
										backdropFilter: "var(--popup-blur)",
										WebkitBackdropFilter: "var(--popup-blur)",
									}}
									labelStyle={{ color: "#9aa6b8" }}
									itemStyle={{ color: "#eef2f8" }}
								/>
								<Bar dataKey="Cost" fill="#2f6fed" radius={[4, 4, 0, 0]} minPointSize={2} />
							</BarChart>
						</ResponsiveContainer>
					</section>

					<SectionTitle icon={<Clock3 size={14} />} text="Last 3 Requests" />
					<section className="recent">
						{dashboard.recentItems.length === 0 ? (
							<p className="empty">No requests yet</p>
						) : (
							dashboard.recentItems.slice(0, 3).map((item) => (
								<div className="request" key={item.id}>
									<span className="model">{shortModel(item.model)}</span>
									<span className="request-tokens flex items-center">
										<ArrowDownIcon size={10} />
										{tokens(item.input_tokens)}
										<span className="mx-1" />
										<ArrowUpIcon size={10} />
										{tokens(item.output_tokens)}
									</span>
									<strong>{formatMoney(item.actual_cost)}</strong>
									<span className="ago">{timeAgo(item.created_at)}</span>
								</div>
							))
						)}
					</section>
				</main>
			)}

			<footer>
				<button className="small-button" onClick={() => refresh()}>
					<RefreshCw size={13} />
					Refresh
				</button>
				<span>{dashboard.lastUpdated ? `Updated ${dashboard.lastUpdated}` : ""}</span>
				<select className="currency-select" value={currency} onChange={(event) => setCurrency(event.target.value)} aria-label="Currency">
					{currencies.map((item) => (
						<option key={item} value={item}>
							{item}
						</option>
					))}
				</select>
				<button className="small-button" onClick={() => invoke("hide_window")}>
					<X size={13} />
					Close
				</button>
			</footer>
			{updateInfo?.update && <Update updateInfo={updateInfo} />}
		</Shell>
	);
}

function Shell({ children, ref }: { children: React.ReactNode; ref?: any }) {
	return (
		<div className="shell" ref={ref}>
			{children}
		</div>
	);
}

function SectionTitle({ icon, text }: { icon: React.ReactNode; text: string }) {
	return (
		<div className="section-title">
			{icon}
			<span>{text}</span>
		</div>
	);
}

function Metric({ label, value, sub, tone = "orange" }: { label: string; value: string; sub: string; tone?: "orange" | "violet" | "green" }) {
	return (
		<div className={`metric ${tone} min-w-fit`}>
			<span className="min-w-fit">{label}</span>
			<div className="min-w-fit">
				<strong>{value}</strong>
			</div>
			<em className="min-w-fit">{sub}</em>
		</div>
	);
}
