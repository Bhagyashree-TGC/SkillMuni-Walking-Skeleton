# L2 — Angular standards

- Follow the conventions already in the repository first; do not restructure folders or rename files outside the work item.
- Standalone components, `OnPush` change detection and typed reactive forms for new code, unless the existing module does otherwise.
- No `any` in new code. Strict null checks respected.
- Keep components small; move logic to services. No direct HTTP calls from components.
- All user-visible text goes through the existing i18n mechanism (English at launch, D-061).
- Accessibility: labels on every form control, keyboard reachable, visible focus, colour contrast to WCAG 2.2 AA.
- Use stable `data-testid` attributes on elements that acceptance tests need.
- No new global styles; use the design system's tokens.
- Run `npm run lint` and `npm run test:ci` locally before opening a pull request, but remember only the pipeline result counts.
