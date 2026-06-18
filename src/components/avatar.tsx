const avatarPalette = ["#2f6fed", "#48d597", "#a992ff", "#ffad5f", "#ff6b5f", "#14b8a6", "#f472b6", "#f59e0b"];

export function pickAvatarColor(seed: string) {
	let hash = 0;
	for (let index = 0; index < seed.length; index += 1) {
		hash = (hash * 31 + seed.charCodeAt(index)) >>> 0;
	}
	return avatarPalette[hash % avatarPalette.length];
}

function avatarTextColor(background: string) {
	const hex = background.replace("#", "");
	const r = Number.parseInt(hex.slice(0, 2), 16);
	const g = Number.parseInt(hex.slice(2, 4), 16);
	const b = Number.parseInt(hex.slice(4, 6), 16);
	const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
	return luminance > 0.55 ? "#111827" : "#f8fafc";
}

function userInitial(email: string) {
	return email.trim().charAt(0).toUpperCase() || "?";
}

export function AccountAvatar({ email, color, size = 22 }: { email?: string; color: string; size?: number }) {
	const background = color || pickAvatarColor(email ?? "");
	return (
		<span
			className="account-avatar"
			style={{
				width: size,
				height: size,
				background,
				color: avatarTextColor(background),
				fontSize: Math.max(10, Math.floor(size * 0.5)),
			}}
			aria-hidden="true">
			{userInitial(email ?? "")}
		</span>
	);
}
