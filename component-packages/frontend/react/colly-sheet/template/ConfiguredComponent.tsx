"use client";

import settings from "./settings.json";
import { Button } from "./button";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "./sheet";

export default function ConfiguredComponent() {
  return <>
    <Sheet><SheetTrigger asChild><Button>{settings.label}</Button></SheetTrigger><SheetContent><SheetHeader><SheetTitle>{settings.title}</SheetTitle><SheetDescription>{settings.description}</SheetDescription></SheetHeader></SheetContent></Sheet>
  </>;
}
