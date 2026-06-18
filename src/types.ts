export type Account = {
	id: string;
	email: string;
	token: string;
	avatarColor: string;
};
export type UpdateInfo = { version: string; date: string; body: string; update: boolean; raw: any; currentVersion:string };
export type DashboardStats = {
	total_api_keys: number;
	active_api_keys: number;
	total_requests: number;
	total_input_tokens: number;
	total_output_tokens: number;
	total_cache_creation_tokens: number;
	total_cache_read_tokens: number;
	total_tokens: number;
	total_cost: number;
	total_actual_cost: number;
	today_requests: number;
	today_input_tokens: number;
	today_output_tokens: number;
	today_cache_creation_tokens: number;
	today_cache_read_tokens: number;
	today_tokens: number;
	today_cost: number;
	today_actual_cost: number;
	average_duration_ms: number;
	rpm: number;
	tpm: number;
};

export type UsageItem = {
	id: number;
	model: string;
	input_tokens: number;
	output_tokens: number;
	cache_read_tokens: number;
	total_cost: number;
	actual_cost: number;
	duration_ms: number;
	first_token_ms: number;
	created_at: string;
};

export type TrendDay = {
	date: string;
	actual_cost: number;
};

export type DashboardData = {
	email: string;
	balance: number;
	stats: DashboardStats;
	recentItems: UsageItem[];
	trend: TrendDay[];
	lastUpdated: string;
};
