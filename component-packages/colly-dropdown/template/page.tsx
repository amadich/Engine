import ConfiguredComponent from "./ConfiguredComponent";

export default function PackagePreview() {
  return (
    <main className="mx-auto max-w-3xl space-y-7 px-8 py-12">
      <a href="/library" className="text-sm underline">Installed components</a>
      <h1 className="text-2xl font-bold">Dropdown Menu</h1>
      <div className="space-y-4 rounded-xl border p-6">
        <ConfiguredComponent />
      </div>
    </main>
  );
}
