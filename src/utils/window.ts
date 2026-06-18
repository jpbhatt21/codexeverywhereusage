import { getCurrentWindow, LogicalSize, PhysicalSize } from "@tauri-apps/api/window";
const curWindow = getCurrentWindow();

export function window() {
	curWindow.setAlwaysOnTop(true);
}

export async function resizeManager(element: HTMLDivElement) {
    // // window.setSize(new LogicalSize(380, 570));
	// console.log("resizeManager called", element.scrollHeight, element.clientHeight);
	// const scrollHeight = element.scrollHeight - element.clientHeight;
	// const horizontalScrollHeight = element.scrollWidth - element.clientWidth;
	// // if (!scrollHeight && !horizontalScrollHeight) {
	// // 	await new Promise((resolve) => setTimeout(resolve, 100));
	// // }
	// const windowDimensions = await curWindow.innerSize();
	// const dpi = await curWindow.scaleFactor();
	// console.log("windowDimensions", windowDimensions);
	// console.log("dpi", dpi);

	curWindow.setSize(new LogicalSize(element.scrollWidth, element.scrollHeight));
}
