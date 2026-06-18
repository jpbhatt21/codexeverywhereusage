import { Update as upd } from "@tauri-apps/plugin-updater";
import { useEffect, useState } from "react";
import { relaunch } from "@tauri-apps/plugin-process";

let prev = 0;
const messages = {
	init: (_perct: number) => "Initializing app update...",
	downloading: (perct: number) => `Downloading update: ${perct}%`,
	finished: (_perct: number) => "Restarting to apply update...",
};
function Update({ updateInfo }: { updateInfo: any }) {
	const [progress, setProgress] = useState({
		state: "init",
		perct: 0,
	});
	useEffect(() => {
		console.log("UpdateInfo in Update component:", updateInfo);
		if (updateInfo?.update && updateInfo?.raw) {
			const updateData = updateInfo.raw as upd;
			let downloaded = 0;
			let contentLength = 0;

			updateData?.download((event: any) => {
				switch (event.event) {
					case "Started":
						contentLength = event.data.contentLength;
						setProgress({
							state: "downloading",
							perct: 0,
						});
						break;
					case "Progress":
						downloaded += event.data.chunkLength;
						prev = Math.floor((downloaded / contentLength) * 100);
						setProgress({
							state: "downloading",
							perct: prev,
						});
						break;
					case "Finished":
						setProgress({
							state: "finished",
							perct: 100,
						});

						break;
				}
			});
		}
	}, [updateInfo]);
	useEffect(() => {
		if (progress.state === "finished") {
			setTimeout(() => {
				updateInfo?.raw
					?.install()
					.then(() => {
						relaunch();
					})
					.catch((err: Error) => {
						console.error("Error installing update:", err);
					});
			}, 2000);
		}
	}, [progress.state, updateInfo]);
	return (
		<footer className="mt-3 gap-2">
			<span className="min-w-fit">{messages[progress.state as keyof typeof messages](progress.perct)}</span>
			<div className="w-full rounded-full overflow-hidden bg-white/20 h-2">
				<div
					className="rounded-r-full animate-pulse bg-blue-500 h-full"
					style={{
						width: `${progress.perct}%`,
					}}
				/>
			</div>
		</footer>
	);
}

export default Update;
