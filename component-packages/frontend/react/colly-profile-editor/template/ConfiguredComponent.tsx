"use client";

import { useState } from "react";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const [saved,setSaved] = useState(false);
  return (
<form className="grid max-w-md gap-3" onSubmit={event => {event.preventDefault();setSaved(true);}}>
      <h2 className="font-bold">{settings.title}</h2>
      <label>Display name <input className="block w-full rounded border p-2" defaultValue={settings.display_name} required maxLength={80} onChange={() => setSaved(false)}/></label>
      {settings.show_bio && <label>Bio <textarea className="block w-full rounded border p-2" defaultValue={settings.bio} maxLength={250} onChange={() => setSaved(false)}/></label>}
      <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50">Save profile</button>
      <p role="status">{saved ? "Saved for this preview" : ""}</p>
    </form>
  );
}
