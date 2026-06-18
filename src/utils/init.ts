import { updater } from "./updater";
import { window } from "./window";
import { platform } from "@tauri-apps/plugin-os";

const os = platform();
if (os === "macos") {
    document.documentElement.setAttribute("data-os", "macos");
} else if (os === "windows") {
    document.documentElement.setAttribute("data-os", "windows");
} else if (os === "linux") {
    document.documentElement.setAttribute("data-os", "linux");
}
export async function init() {
	window();
	return await updater();
}
