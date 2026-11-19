"use client";

import type { ComponentProps } from "react";
import settings from "./settings.json";
import { Button } from "./button";

type ButtonProps = ComponentProps<typeof Button>;

export default function ConfiguredComponent(props: ButtonProps) {
  return (
    <Button variant={settings.variant as ButtonProps["variant"]} size={settings.size as ButtonProps["size"]} {...props}>
      {props.children ?? settings.label}
    </Button>
  );
}
