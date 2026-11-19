"use client";


import settings from "./settings.json";

export default function ConfiguredComponent() {
  const members = [...new Set(settings.members.split(",").map(value => value.trim()).filter(Boolean))];
  return (
<section><h2 className="mb-3 font-bold">{settings.title}{settings.show_count && ` (${members.length})`}</h2>
      <ul className="flex flex-wrap gap-3">{members.map(member => <li key={member} className="flex items-center gap-2 rounded-full border px-3 py-2">
        <span className="size-2 rounded-full bg-green-600" aria-label="Online"/>{member}</li>)}</ul>
    </section>
  );
}
