import type { Account, DashboardData } from "./types";

const accountsKey = "codex_accounts";
const activeKey = "codex_active_account";
const cacheKey = "codex_dashboard_cache";

export function readAccounts(): Account[] {
  try {
    return JSON.parse(localStorage.getItem(accountsKey) ?? "[]");
  } catch {
    return [];
  }
}

export function saveAccounts(accounts: Account[]) {
  localStorage.setItem(accountsKey, JSON.stringify(accounts));
}

export function readActiveAccount(): Account | null {
  try {
    return JSON.parse(localStorage.getItem(activeKey) ?? "null");
  } catch {
    return null;
  }
}

export function saveActiveAccount(account: Account | null) {
  if (account) localStorage.setItem(activeKey, JSON.stringify(account));
  else localStorage.removeItem(activeKey);
}

export function readDashboardCache(): DashboardData | null {
  try {
    return JSON.parse(localStorage.getItem(cacheKey) ?? "null");
  } catch {
    return null;
  }
}

export function saveDashboardCache(data: DashboardData) {
  localStorage.setItem(cacheKey, JSON.stringify(data));
}
