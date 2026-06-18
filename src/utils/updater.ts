import { check, type Update } from "@tauri-apps/plugin-updater";
import { getVersion } from "@tauri-apps/api/app";
import { UpdateInfo } from "../types";
import { platform } from "@tauri-apps/plugin-os";
const os = platform();
export async function updater() : Promise<UpdateInfo> {
	const VERSION = await getVersion();
	console.log(`App Version: ${VERSION}`);
    const clientDate = localStorage.getItem("cem-clientDate") || Date.now().toString();
    // get health check on 'https://health.codex.xyz.com/VERSION/os/clientDate'

	let update: Update | null = null;
	try {
		const timeoutPromise = new Promise<never>((_, reject) => setTimeout(() => reject(new Error("Update check timeout")), 20000));
		update = await Promise.race([check(), timeoutPromise]);
	} catch (error) {
        console.log("Error checking for updates:", error instanceof Error ? error.message : error);
		update = null;
	}
    console.log(update)
	if (update) {
		let lang = "en";
		let parsedBody: any = {};
		if (update.body) {
			try {
				parsedBody = JSON.parse(update.body);
				parsedBody = parsedBody[lang as keyof typeof parsedBody] || parsedBody;
			} catch (e) {
				parsedBody = {};
			}
		}
		return {
			version: update.version,
            currentVersion: VERSION,
			date: update.date || "",
			body: JSON.stringify(parsedBody) || "{}",
			update: true,
			raw: update,
		};
	}
	return {
		version: VERSION,
        currentVersion: VERSION,
		update: false,
		date: "",
		body: "{}",
		raw: null,
	};
}
