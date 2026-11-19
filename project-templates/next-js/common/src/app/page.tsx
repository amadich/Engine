import Link from "next/link";

export default function Home() {
  return (
    <main className="mx-auto max-w-3xl space-y-6 px-8 py-20">
      <h1 className="text-4xl font-bold">__NAME__</h1>
      <Link href="/library" className="underline">Installed components</Link>
    </main>
  );
}
