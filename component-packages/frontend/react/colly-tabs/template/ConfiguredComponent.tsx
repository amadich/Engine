"use client";

import { Tabs } from "radix-ui";
import settings from "./settings.json";

export default function ConfiguredComponent() {

  return (
<Tabs.Root defaultValue="first" className="space-y-3">
      <Tabs.List aria-label="Project sections" className="flex gap-2">
        <Tabs.Trigger className="rounded border px-3 py-2 data-[state=active]:bg-muted" value="first">{settings.first_tab}</Tabs.Trigger>
        <Tabs.Trigger className="rounded border px-3 py-2 data-[state=active]:bg-muted" value="second">{settings.second_tab}</Tabs.Trigger>
      </Tabs.List>
      <Tabs.Content value="first">{settings.first_content}</Tabs.Content>
      <Tabs.Content value="second">{settings.second_content}</Tabs.Content>
    </Tabs.Root>
  );
}
