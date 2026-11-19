import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import Link from "next/link";

export const dynamic = "force-dynamic";

export default function Library() {
  const directory = join(process.cwd(), "src/app/library");
  const packages = readdirSync(directory, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && /^[a-z0-9-]+$/.test(entry.name)
      && existsSync(join(directory, entry.name, "page.tsx")))
    .map(entry => entry.name)
    .sort();

  return (
    <main className="mx-auto max-w-3xl space-y-6 px-8 py-12">
      <Link href="/" className="underline">Home</Link>
      <h1 className="text-3xl font-bold">Installed components</h1>
      {packages.length ? (
        <ul className="grid gap-3 sm:grid-cols-2">
          {packages.map(name => (
            <li key={name}>
              <Link className="block rounded-lg border p-4 hover:bg-muted" href={`/library/${name}`}>
                {name.replaceAll("-", " ")}
              </Link>
            </li>
          ))}
        </ul>
      ) : <p>Choose a component in Jeridi Engine and install it to its suggested folder.</p>}
    </main>
  );
}
