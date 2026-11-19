"use client";

import settings from "./settings.json";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./select";

export default function ConfiguredComponent() {
  return <>
    <Select><SelectTrigger aria-label={settings.placeholder}><SelectValue placeholder={settings.placeholder} /></SelectTrigger><SelectContent><SelectItem value="first">{settings.firstOption}</SelectItem><SelectItem value="second">{settings.secondOption}</SelectItem></SelectContent></Select>
  </>;
}
