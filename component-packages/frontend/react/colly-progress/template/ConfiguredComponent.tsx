"use client";

import { useState } from "react";
import { Progress } from "radix-ui";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const [value,setValue] = useState(settings.initial);
  return (
<section className="space-y-3"><p>{settings.label} · {value}%</p>
      <Progress.Root className="h-3 overflow-hidden rounded-full bg-muted" value={value} aria-label={settings.label}>
        <Progress.Indicator className="h-full bg-primary transition-all" style={{width: `${value}%`}}/>
      </Progress.Root>
      <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" onClick={() => setValue(value === 100 ? 0 : Math.min(100,value + settings.step))}>Advance</button>
    </section>
  );
}
