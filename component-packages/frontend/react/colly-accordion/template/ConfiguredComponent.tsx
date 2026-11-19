"use client";

import { Accordion } from "radix-ui";
import settings from "./settings.json";

export default function ConfiguredComponent() {

  return (
<Accordion.Root type="single" collapsible defaultValue={settings.open_by_default ? "details" : undefined}>
      <Accordion.Item value="details" className="rounded border p-3">
        <Accordion.Header><Accordion.Trigger className="font-semibold">{settings.title} ▾</Accordion.Trigger></Accordion.Header>
        <Accordion.Content className="pt-3">{settings.summary}</Accordion.Content>
      </Accordion.Item>
    </Accordion.Root>
  );
}
