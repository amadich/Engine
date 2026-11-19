# Component packages

- `frontend/react`: React packages shared by Next.js and Vite.
- `frontend/react-vite`, `frontend/vue-vite`, `frontend/html`: framework-specific packages.
- `backend/express-ts`, `backend/spring-boot`: backend packages.
- `_shared`: assets referenced by several package manifests.

Keep each manifest's `id` stable when moving its source directory. Projects record the ID and the actual install path. The manifest declares compatible frameworks, catalog categories, template mappings, dependencies, and editable fields. Set `technologies` to make a package discoverable in the Technologies dialog. Use `usage` to explain how the engineer wires the installed exports.

For React packages, place editable values in `template/settings.json`, import them in `ConfiguredComponent.tsx`, and expose a Next.js `page.tsx`. Declare the Vite preview files under `viteFiles`. Update the shared Vite stylesheet when introducing new Tailwind utility classes.
