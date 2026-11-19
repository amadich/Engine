"use client";

import settings from "./settings.json";
import { Textarea } from "./textarea";
import { Label } from "./label";

export default function ConfiguredComponent() {
  return <>
    <Label htmlFor="demo-textarea">{settings.label}</Label><Textarea id="demo-textarea" placeholder={settings.placeholder} />
  </>;
}
