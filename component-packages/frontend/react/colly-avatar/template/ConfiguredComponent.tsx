"use client";

import settings from "./settings.json";
import { Avatar, AvatarFallback } from "./avatar";

export default function ConfiguredComponent() {
  return <>
    <div className="flex items-center gap-3"><Avatar><AvatarFallback>{settings.initials}</AvatarFallback></Avatar><span>{settings.label}</span></div>
  </>;
}
