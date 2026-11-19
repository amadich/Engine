"use client";

import { useState, type FormEvent } from "react";
import { Button } from "./button";
import { Input } from "./input";
import { Label } from "./label";
import settings from "./settings.json";

type Csrf = { headerName: string; token: string };

export default function ConfiguredComponent() {
  const [status, setStatus] = useState("");
  const [working, setWorking] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const values = new FormData(form);
    const username = values.get("username");
    const password = values.get("password");
    setWorking(true);
    setStatus("");
    try {
      const auth = new URL("/api/v1/auth/", settings.apiOrigin);
      const csrf = await fetch(new URL("csrf", auth), { credentials: "include", cache: "no-store" });
      if (!csrf.ok)
        throw new Error("Enable cookie mode in the Spring Application Environment package.");
      const { headerName, token }: Csrf = await csrf.json();
      const login = await fetch(new URL("login", auth), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json", [headerName]: token },
        body: JSON.stringify({ username, password }),
      });
      if (!login.ok)
        throw new Error(login.status === 401 ? "Invalid username or password." : "Sign-in failed.");
      form.reset();
      setStatus("Signed in.");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Sign-in failed.");
    } finally {
      setWorking(false);
    }
  }

  return (
    <form className="max-w-sm space-y-4" onSubmit={submit}>
      <h2 className="text-xl font-semibold">{settings.title}</h2>
      <Label className="grid gap-2">
        {settings.usernameLabel}
        <Input name="username" autoComplete="username" required />
      </Label>
      <Label className="grid gap-2">
        {settings.passwordLabel}
        <Input name="password" type="password" autoComplete="current-password" required />
      </Label>
      <Button type="submit" disabled={working}>{settings.buttonLabel}</Button>
      <p role="status" aria-live="polite">{status}</p>
    </form>
  );
}
