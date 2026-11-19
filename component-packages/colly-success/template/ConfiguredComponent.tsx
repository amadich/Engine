"use client";

import settings from "./settings.json";
import { useState } from "react";
import { Button } from "./button";
import SuccessDialog from "./SuccessDialog";

export default function ConfiguredComponent() {
  const [open, setOpen] = useState(false);
  return <>
    <Button onClick={() => setOpen(true)}>{settings.label}</Button><SuccessDialog open={open} onOpenChange={setOpen} title={settings.title} description={settings.description} />
  </>;
}
