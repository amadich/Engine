import settings from "./settings.json";
import ConfiguredComponent from "./ConfiguredComponent";

export default function Preview() {
  return <main className="mx-auto max-w-3xl space-y-5 p-8">
    <a className="underline" href="/library">Installed components</a>
    <h1 className="text-2xl font-bold">{settings.previewTitle}</h1>
    <ConfiguredComponent />
  </main>;
}
