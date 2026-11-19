"use client";

import settings from "./settings.json";
import ChatBubble, { ControlButton } from "./ChatBubble";

export default function ConfiguredComponent() {
  return <>
    <div className="flex min-h-40 items-end justify-center"><div className="relative"><ChatBubble content={settings.content} color={settings.color} /><ControlButton label="Room member" /></div></div>
  </>;
}
