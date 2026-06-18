import type { Account, DashboardData } from "../types";

const accountsKey = "codex_accounts";
const activeKey = "codex_active_account";
const cacheKey = "codex_dashboard_cache";
const currencyKey = "codex_currency";
const exchangeRateKey = "codex_exchange_rate";

export type ExchangeRateCache = {
  currency: string;
  rate: number;
  fetchedAt: number;
};

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

export function readCurrencyPreference() {
  return localStorage.getItem(currencyKey) ?? "USD";
}

export function saveCurrencyPreference(currency: string) {
  localStorage.setItem(currencyKey, currency);
}

export function readExchangeRateCache(): ExchangeRateCache | null {
  try {
    return JSON.parse(localStorage.getItem(exchangeRateKey) ?? "null");
  } catch {
    return null;
  }
}

export function saveExchangeRateCache(data: ExchangeRateCache) {
  localStorage.setItem(exchangeRateKey, JSON.stringify(data));
}

export function removeAccount(account: Account) {
  const accounts = readAccounts();
  const filtered = accounts.filter((a) => a.id !== account.id);
  saveAccounts(filtered);
  const active = readActiveAccount();
  if (active?.id === account.id) {
    saveActiveAccount(null);
    localStorage.removeItem(cacheKey)
  }
  window.location.reload();
}