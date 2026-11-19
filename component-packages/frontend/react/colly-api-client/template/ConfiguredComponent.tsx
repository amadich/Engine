"use client";

import { useState } from "react";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const [result,setResult] = useState("");
  const [busy,setBusy] = useState(false);
  async function read() {
    setBusy(true);
    try {
      const response = await fetch(settings.endpoint, {
        method: settings.method, signal: AbortSignal.timeout(settings.timeout_ms), credentials: "omit"
      });
      const text = (await response.text()).slice(0, 4000);
      setResult(`${response.status} ${response.statusText}\n${text}`);
    } catch (error) {
      setResult(error instanceof Error ? error.message : "Request failed");
    } finally {
      setBusy(false);
    }
  }
  return (
<section className="space-y-3">
      <h2 className="font-bold">{settings.title}</h2>
      <p className="break-words text-sm">{settings.method} {settings.endpoint}</p>
      <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" disabled={busy} onClick={read}>Send request</button>
      <pre role="status" className="max-h-64 overflow-auto whitespace-pre-wrap rounded border p-3">{result}</pre>
    </section>
  );
}
