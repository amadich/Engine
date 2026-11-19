"use client";

import settings from "./settings.json";
import { useState } from "react";
import { motion, useReducedMotion } from "motion/react";
import { Button } from "./button";

export default function ConfiguredComponent() {
  const [attempt, replay] = useState(0);
  const reduceMotion = useReducedMotion();
  return <>
    <Button onClick={() => replay(value => value + 1)}>{settings.label}</Button><motion.div key={attempt} className="mt-4 rounded-lg bg-primary p-10 text-primary-foreground" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: reduceMotion ? 0 : settings.duration / 1000 }}>{settings.title}</motion.div>
  </>;
}
