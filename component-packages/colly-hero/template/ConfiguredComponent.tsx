"use client";

import { ChevronRight } from "@mynaui/icons-react";
import { motion, useReducedMotion } from "motion/react";
import hero from "./hero.webp";

function assetUrl(asset: string | { src: string }) {
  return typeof asset === "string" ? asset : asset.src;
}
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const reducedMotion = useReducedMotion();

  return (
    <section className="mx-auto flex w-full flex-col gap-8 text-center">
      <div className="mx-auto max-w-lg space-y-4">
        <h2 className="text-balance text-4xl font-bold tracking-tight">{settings.title}</h2>
        <p className="text-muted-foreground">{settings.description}</p>
        <a className="inline-flex items-center gap-2 rounded-full bg-primary px-5 py-2 text-primary-foreground" href={settings.href}>
          {settings.label}
          <ChevronRight aria-hidden className="size-5" />
        </a>
      </div>
      <motion.div
        initial={reducedMotion ? false : { opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: reducedMotion ? 0 : 0.7 }}
      >
        <img src={assetUrl(hero)} width={2752} height={1536} alt={settings.imageAlt} className="h-auto w-full rounded-lg" />
      </motion.div>
    </section>
  );
}
