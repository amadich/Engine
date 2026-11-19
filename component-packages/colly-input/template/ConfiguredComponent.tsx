"use client";

import settings from "./settings.json";
import { Input } from "./input";
import { Label } from "./label";

export default function ConfiguredComponent() {
  return <>
    <Label htmlFor="demo-input">{settings.label}</Label><Input id="demo-input" type="email" placeholder={settings.placeholder} />
  </>;
}
