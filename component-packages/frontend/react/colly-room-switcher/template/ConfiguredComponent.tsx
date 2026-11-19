"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import settings from "./settings.json";

export default function ConfiguredComponent() {
  const rooms = [...new Set(settings.rooms.split(",").map(value => value.trim()).filter(Boolean))];
  const [active, setActive] = useState(rooms[0]);
  const [open, setOpen] = useState(settings.initial_open);
  return (
<section className="space-y-3">
      <button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" aria-expanded={open} onClick={() => setOpen(!open)}>{settings.title} · {active || "Select"}</button>
      <AnimatePresence>{open && <motion.ul initial={{opacity:0}} animate={{opacity:1}} exit={{opacity:0}} className="space-y-2">
        {rooms.map(room => <li key={room}><button className="rounded-md border px-3 py-2 text-sm font-semibold disabled:opacity-50" aria-pressed={room === active} onClick={() => {setActive(room);setOpen(false);}}>{room}</button></li>)}
      </motion.ul>}</AnimatePresence>
    </section>
  );
}
