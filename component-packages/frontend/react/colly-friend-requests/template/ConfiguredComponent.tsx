"use client";

import { useState } from "react";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const [people,setPeople] = useState([...new Set(settings.people.split(",").map(value => value.trim()).filter(Boolean))]);
  const [status,setStatus] = useState("");
  function decide(person: string, action: string) {
    setPeople(previous => previous.filter(value => value !== person));
    setStatus(`${action} request from ${person}`);
  }
  return (
<section className="space-y-3"><h2 className="font-bold">{settings.title}</h2>
      {people.length === 0 ? <p>{settings.empty_message}</p> : <ul className="space-y-2">{people.map(person =>
        <li key={person} className="flex items-center gap-2 rounded border p-3"><b className="grow">{person}</b>
          <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" onClick={() => decide(person,"Accepted")}>Accept</button>
          <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" onClick={() => decide(person,"Declined")}>Decline</button></li>)}</ul>}
      <p role="status">{status}</p></section>
  );
}
