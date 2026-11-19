"use client";

import settings from "./settings.json";

export default function ConfiguredComponent() {
  return <>
    <article className="max-w-sm rounded-xl border-2 border-black bg-lime-200 p-6 text-black shadow-[4px_4px_0px_#000]"><h2 className="text-sm font-semibold">{settings.title}</h2><p className="text-4xl font-black">{settings.value}</p><p className="mt-2">{settings.description}</p></article>
  </>;
}
