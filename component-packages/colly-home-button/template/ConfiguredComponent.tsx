"use client";

import settings from "./settings.json";
import { motion } from "motion/react";
import { House } from "lucide-react";

export default function ConfiguredComponent() {
  return <>
    <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.97 }} className="w-fit"><a href={settings.destination} className="inline-flex items-center gap-2 rounded-full border-2 border-black bg-yellow-300 px-5 py-3 font-bold text-black"><House aria-hidden size={20} />{settings.label}</a></motion.div>
  </>;
}
