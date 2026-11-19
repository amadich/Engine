"use client";

import settings from "./settings.json";
import { Checkbox } from "./checkbox";
import { Label } from "./label";

export default function ConfiguredComponent() {
  return <>
    <div className="flex items-center gap-2"><Checkbox id="demo-check" /><Label htmlFor="demo-check">{settings.label}</Label></div>
  </>;
}
