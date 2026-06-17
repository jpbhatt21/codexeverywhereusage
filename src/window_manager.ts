import { getCurrentWindow, LogicalSize, PhysicalSize } from "@tauri-apps/api/window";
const window = getCurrentWindow();
export function init(){
    window.setAlwaysOnTop(true);
}

export async function resizeManager(element:HTMLDivElement){
    console.log("resizeManager called", element.scrollHeight, element.clientHeight);
    const scrollHeight = element.scrollHeight - element.clientHeight;
    const windowDimensions = await window.innerSize();
    const dpi = await window.scaleFactor();
    console.log("windowDimensions", windowDimensions); console.log("dpi", dpi);
    // window.setSize(new LogicalSize(380, 570));
    if(scrollHeight){
        window.setSize(new PhysicalSize(windowDimensions.width, Math.ceil(scrollHeight * dpi) + windowDimensions.height));
    }
}