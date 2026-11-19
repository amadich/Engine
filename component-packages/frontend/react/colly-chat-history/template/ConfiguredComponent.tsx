"use client";

import { useState } from "react";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const [messages, setMessages] = useState([settings.message]);
  const [draft, setDraft] = useState("");
  return (
<section className="space-y-3">
      <h2 className="font-bold">{settings.title}</h2>
      <ol aria-live="polite" className="max-h-60 space-y-2 overflow-auto">
        {messages.map((message,index) => <li key={index} className="rounded border p-3"><b>{settings.author}</b> · {message}</li>)}
      </ol>
      <form className="flex gap-2" onSubmit={event => {event.preventDefault(); if (!draft.trim()) return;
        setMessages(previous => [...previous, draft.trim()].slice(-settings.limit)); setDraft(""); }}>
        <input className="rounded border px-2" aria-label="Message" value={draft} maxLength={500} onChange={event => setDraft(event.target.value)}/>
        <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50">Send</button>
      </form>
    </section>
  );
}
