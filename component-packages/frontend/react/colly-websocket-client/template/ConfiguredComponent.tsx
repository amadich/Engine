"use client";

import { useEffect, useRef, useState } from "react";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const socket = useRef<WebSocket | null>(null);
  const [state,setState] = useState("Disconnected");
  const [input,setInput] = useState("");
  const [messages,setMessages] = useState<string[]>([]);
  useEffect(() => () => { const current = socket.current; socket.current = null; current?.close(); }, []);
  function disconnect() {
    const current = socket.current;
    socket.current = null;
    current?.close();
    setState("Disconnected");
  }
  function connect() {
    if (socket.current) return;
    try {
      const connection = new WebSocket(settings.endpoint);
      socket.current = connection;
      setState("Connecting");
      connection.onopen = () => { if (socket.current === connection) setState("Open"); };
      connection.onerror = () => { if (socket.current === connection) setState("Connection error"); };
      connection.onclose = () => {
        if (socket.current !== connection) return;
        socket.current = null;
        setState(previous => previous === "Connection error" ? previous : "Disconnected");
      };
      connection.onmessage = (event) => {
        if (socket.current !== connection || typeof event.data !== "string") return;
        setMessages(previous => [...previous, event.data.slice(0,1000)].slice(-settings.history_limit));
      };
    } catch {
      setState("Invalid WebSocket endpoint");
    }
  }
  return (
<section className="space-y-3">
      <h2 className="font-bold">{settings.title}</h2>
      <p role="status">{state}</p>
      <div className="flex gap-2"><button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" disabled={state === "Open" || state === "Connecting"} onClick={connect}>Connect</button>
        <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" disabled={state !== "Open" && state !== "Connecting"} onClick={disconnect}>Disconnect</button></div>
      <form className="flex gap-2" onSubmit={event => {event.preventDefault();
        if (socket.current?.readyState === WebSocket.OPEN && input.trim()) { socket.current.send(input);setInput(""); } }}>
        <input aria-label="Message" className="rounded border px-2" maxLength={1024} value={input} onChange={event => setInput(event.target.value)} />
        <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" disabled={state !== "Open"}>{settings.send_label}</button>
      </form>
      <ul aria-live="polite">{messages.map((message,index) => <li key={index} className="break-words">{message}</li>)}</ul>
    </section>
  );
}
