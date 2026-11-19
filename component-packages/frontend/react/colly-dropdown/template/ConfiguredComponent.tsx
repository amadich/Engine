"use client";

import settings from "./settings.json";
import { Button } from "./button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "./dropdown-menu";

export default function ConfiguredComponent() {
  return <>
    <DropdownMenu><DropdownMenuTrigger asChild><Button>{settings.label}</Button></DropdownMenuTrigger><DropdownMenuContent><DropdownMenuItem>{settings.firstOption}</DropdownMenuItem><DropdownMenuItem>{settings.secondOption}</DropdownMenuItem></DropdownMenuContent></DropdownMenu>
  </>;
}
