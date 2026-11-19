"use client";

import settings from "./settings.json";
import { motion } from "motion/react";
import { ChevronRight } from "@mynaui/icons-react";

export default function ConfiguredComponent() {
  return <>
    <motion.nav aria-label="Primary" className="flex items-center justify-between rounded-lg border-2 border-black p-4 font-bold text-black" style={{ backgroundColor: settings.background }} initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }}><span>{settings.brand}</span><a className="inline-flex items-center gap-2" href={settings.href}>{settings.label}<ChevronRight aria-hidden size={20} /></a></motion.nav>
  </>;
}
