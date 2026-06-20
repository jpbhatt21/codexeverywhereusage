import { invoke } from "@tauri-apps/api/core";
import { Brain, Check } from "lucide-react";
import { FormEvent, useEffect, useState } from "react";
import { AccountAvatar, pickAvatarColor } from "./components/avatar";
import type { Account, UpdateInfo } from "./types";

function Login({ accounts, onLogin, onSwitch, compact = false, updateInfo, initialEmail = "", message = "" }: { accounts: Account[]; onLogin: (account: Account) => void; onSwitch: (account: Account) => void; compact?: boolean, updateInfo:UpdateInfo; initialEmail?: string; message?: string }) {
	const [email, setEmail] = useState(initialEmail);
	const [password, setPassword] = useState("");
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState(message);

	useEffect(() => {
		setEmail(initialEmail);
		setError(message);
	}, [initialEmail, message]);

	const submit = async (event: FormEvent) => {
		event.preventDefault();
		setLoading(true);
		setError("");
		try {
			const token = (await invoke("login", { email, password })) as string;
			const avatarColor = pickAvatarColor(email);
			onLogin({ id: email, email, token, avatarColor });
			setEmail("");
			setPassword("");
		} catch (err) {
			setError(err instanceof Error ? err.message : "Login failed");
		} finally {
			setLoading(false);
		}
	};

	return (
		<main className={compact ? "login compact-login my-8" : "login flex flex-col items-center justify-center -mt-16"}>
			<Brain size={compact ? 32 : 48} className="login-icon" />
			<h2>Codex Everywhere</h2>
            <div className="-mt-4 text-xs opacity-50">{updateInfo.currentVersion && `v${updateInfo.currentVersion}`}</div>
			<p>Sign in to your account</p>
			<form onSubmit={submit}>
				<input value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Email" type="email" />
				<input value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Password" type="password" />
				{error && <div className="error">{error}</div>}
				<button disabled={!email || !password || loading}>{loading ? "Signing In..." : "Sign In"}</button>
			</form>
			{accounts.length > 0 && (
				<div className="switcher">
					<span>Or switch account</span>
					{accounts.map((account) => (
						<button key={account.id} onClick={() => onSwitch(account)}>
							<AccountAvatar email={account.email} color={account.avatarColor} size={16} />
							{account.email}
							<Check size={15} />
						</button>
					))}
				</div>
			)}
		</main>
	);
}

export default Login;
