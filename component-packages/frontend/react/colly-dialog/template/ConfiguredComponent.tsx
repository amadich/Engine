"use client";

import settings from "./settings.json";
import { Button } from "./button";
import { Dialog, DialogContent, DialogDescription, DialogTitle, DialogTrigger } from "./dialog";

export default function ConfiguredComponent() {
  return <>
    <Dialog><DialogTrigger asChild><Button>{settings.label}</Button></DialogTrigger><DialogContent><DialogTitle>{settings.title}</DialogTitle><DialogDescription>{settings.description}</DialogDescription></DialogContent></Dialog>
  </>;
}
