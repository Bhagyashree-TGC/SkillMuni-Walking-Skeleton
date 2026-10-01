# skillmuni-ecosystem-docs

Program-level documentation for the SkillMuni Ecosystem (decision D-055). Each of the six platforms has its
own docs repository with the same folders; ISO evidence lives in `tgc-iso-compliance` and the immutable
evidence vault.

| Folder | Holds |
| --- | --- |
| overview/ | Program overview and the approved factory design documents |
| requirements/ | Program-level requirements and cross-platform rules |
| architecture/ | Architecture, decisions (ADRs), integration contracts |
| api/ | Shared API and event contracts |
| data/ | Data model, ownership, residency |
| security/ | Identity (Keycloak), threat models, security decisions |
| operations/ | Runbooks, environments, monitoring, recovery |
| testing/ | Test strategy and reports |
| compliance/ | POPIA, GDPR, DPDP, NDPA, Sri Lanka PDPA and ISO mapping |
| guides/ | How-to guides for people |
| changes/ | Automatic change records |
| releases/ | Release notes and approvals |

**Naming:** `{ProjectID}-{Type}-{Title}-v{major}.{minor}` (Operating Model, document labelling).
**Access:** downloads only for people with access to this repository (DR-13). No secrets, no personal data.
**Changes:** by pull request with Level 1 (Tech Lead) and Level 2 (CEO or Deputy CEO) approval.
