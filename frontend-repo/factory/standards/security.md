# L2 — Security standards

- Never commit secrets. The pipeline runs a secret scan; a finding fails the build.
- Never log tokens, personal data or full request bodies.
- Do not bypass Angular's sanitisation (`bypassSecurityTrust*`) without a security review.
- Route guards are a convenience, not security; the backend decides access.
- Tokens from Keycloak stay in memory or the library's secure storage; never in `localStorage` unless the existing app already does and the work item is not about it.
- Any change to sign-in, roles, Keycloak configuration or Content-Security-Policy needs the security authority and both approval levels (D-059). Stop and ask.
