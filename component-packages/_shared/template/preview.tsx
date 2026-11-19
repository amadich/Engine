/// <reference types="vite/client" />
import { createRoot } from "react-dom/client";
import ConfiguredComponent from "./ConfiguredComponent";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(
    <main className="mx-auto max-w-3xl p-8">
      <div className="space-y-4 rounded-xl border border-border p-6">
        <ConfiguredComponent />
      </div>
    </main>
  );
}
