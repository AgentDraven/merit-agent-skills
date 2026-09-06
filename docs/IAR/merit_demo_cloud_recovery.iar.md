# MERIT Demo Cloud-Recovery IAR

## Purpose

This IAR defines the recovery and reference-consumer plan for `merit-demo`. It makes the consumer honest about its hosted runtime state, provides a usable fallback, and keeps marketing independently available. It is a planning artifact only: no requirement below claims implementation or deployment completion.

## Current evidence and interpretation

| Observation | Established fact | Not established | Current state |
| --- | --- | --- | --- |
| Hub installer cloned `merit-demo` | The local consumer repository was seeded | MERIT skills were installed or cloud checks passed | Confirmed |
| Local `play/index.html` opened | A static local page launched | Hosted workbench initialized | Confirmed |
| Page referenced `merit_workbench@0.4.0` at `merit-prod.vercel.app` | The demo attempted to use that runtime reference | The remote asset was healthy, compatible, or usable | Inconclusive |
| Page remained at `Loading workbench...` | Bootstrap did not visibly reach a ready state | Cause of failure | Unverified |
| No verified portal URL | None | A here.now marketing portal is published/reachable | Unverified |

The prior local shell/tool startup issue is an agent-environment limitation only. It is not evidence that Vercel, here.now, `.cursor`, or MERIT services are unavailable.

## Zone model

| Zone | Meaning | Primary responsibility |
| --- | --- | --- |
| A | Cursor + Hub laptop follow-through when a new repository is seeded | Seed receipts, `.cursor` verification, local HTTP validation |
| B | `merit-agent-skills` / Hub scripts and documentation | Reusable validation, templates, hygiene, and skill consolidation |
| C | `merit-demo` as the exemplar hello-world consumer | Runtime startup, compatibility, fallback, and consumer documentation |
| D | `merit-prod` CDN/store/OC plus here.now marketing | Hosted runtime contract, release metadata, CORS, and portal availability |

## Target relationship

```text
Hub seed (A) --> MERIT skills/rules in .cursor (B)
                    |
                    v
          shared cloud-readiness checker (B)
                    |
                    v
merit-demo (C) --> verified merit-prod runtime (D: Vercel)
       |                         |
       |                         +-- unavailable/incompatible
       v
local interactive fallback --> independent marketing portal (D: here.now)
```

`merit-agent-skills` is a development and validation dependency. It is not a browser runtime dependency. `merit-prod` is the hosted workbench/runtime plane. `portal/` is a standalone public marketing plane with no runtime dependency on Vercel.

## Functional requirements

The base number links the same feature across zones. Each zone suffix represents a separately accountable requirement and evidence row.

| FR | Zone | Requirement | Cross-links and dependencies |
| --- | --- | --- | --- |
| FR-001-A | A | Hub receipts must distinguish clone success, local-page launch, remote-runtime configuration, and verified cloud runtime. | Uses FR-001-B; prevents an unverified hosted claim in FR-001-C. |
| FR-001-B | B | Define a normalized validation receipt containing target, check, status, expected and observed version, timestamp, evidence, reason, and remediation. | Used by A, C, and D. |
| FR-001-C | C | The consumer may show Hosted Ready only after a verified receipt and successful browser initialization. | Depends on FR-001-B and FR-001-D. |
| FR-001-D | D | Every hosted runtime release must expose verifiable health and immutable deployment metadata. | Supplies the evidence consumed in B and C. |
| FR-002-A | A | A seeded consumer repository must verify required MERIT skills/rules in `.cursor`. | Uses FR-002-B; evidence is recorded by FR-010-C. |
| FR-002-B | B | Extend existing consumer scaffold/install validation; do not introduce a standalone public availability skill. | Supports A and C. |
| FR-002-C | C | Record installed MERIT skill/rule identifiers and versions in consumer evidence. | Depends on FR-002-A/B. |
| FR-003-B | B | Implement one internal shared cloud-readiness checker reused by Vercel, portal, and hygiene workflows. | No new public skill; avoids duplicate verification logic. |
| FR-003-C | C | Keep runtime base URL, exact expected workbench version, health endpoint, and portal URL in one consumer configuration surface. | Verified through B against D. |
| FR-003-D | D | Expose public no-cache `GET /api/health` with status, service, exact workbench version, deployment ID, build SHA, and deployed timestamp. | Contract consumed by FR-003-B/C and version policy in FR-004. |
| FR-004-B | B | Harden `merit-deploy-vercel` to validate schema, HTTP status, freshness, version, CORS, remote assets, and browser readiness. | Uses FR-003-D and emits FR-001-B receipts. |
| FR-004-C | C | Import the hosted workbench only when the observed version exactly equals the configured pin. | Depends on FR-003-C/D and FR-004-B. |
| FR-004-D | D | Publish actual workbench version metadata and permit approved consumer origins to load the hosted asset. | Version/CORS failures route to FR-005-C. |
| FR-005-C | C | Replace indefinite loading with Checking, Hosted Ready, Demo Fallback, and Runtime Unavailable states. | Error categories come from FR-004-B/D. |
| FR-005-D | D | Make runtime failures diagnosable: non-200 health, malformed metadata, version mismatch, CORS rejection, asset failure, and initialization failure. | Tested in FR-011-D and handled in C. |
| FR-006-C | C | Provide a functional local interactive fallback, labeled offline demo, including reason, retry, and portal link. | Must work when D is unreachable. |
| FR-006-D | D | Ensure the here.now portal has no build-time or runtime dependency on `merit-prod`. | Is the independent destination linked by FR-006-C. |
| FR-007-B | B | Harden `merit-portal` to publish and independently verify portal releases. | Reuses FR-003-B where appropriate. |
| FR-007-C | C | Keep consumer marketing source in `portal/` and link to it from all non-ready states. | Publication/verification are owned by B/D. |
| FR-007-D | D | Publish only `merit-demo/portal/` to here.now and verify rendering while Vercel is unavailable. | Satisfies FR-006-D. |
| FR-008-B | B | Extend `merit-hygiene` to aggregate installation, Vercel, portal, documentation, and IAR evidence into a release gate. | Rejects absent, stale, conflicting, or unverified evidence. |
| FR-008-C | C | Link consumer claims to IAR evidence rather than asserting cloud readiness in prose. | Consumes FR-001-B receipt schema. |
| FR-008-D | D | Retain Vercel and here.now release evidence URLs and timestamps. | Input to FR-008-B/C. |
| FR-009-B | B | Audit all MERIT skills for overlapping consumer deployment/validation duties and merge only proven duplicates into retained skills. | Keep distinct lifecycle, product, research, security, and operator functions. |
| FR-009-C | C | Consumer documentation and `.cursor` guidance must reference only retained skills after the B audit. | Depends on FR-009-B migration mapping. |
| FR-010-B | B | Supply reusable templates/blobs for usage, design, cloud report, and IAR evidence. | Feeds consumer documentation. |
| FR-010-C | C | Maintain usage, design, cloud-report, and recovery-IAR documents with cross-links. | This document is the controlling recovery IAR. |
| FR-011-A | A | Validate the seeded consumer through a local HTTP server; `file://` is static smoke-only. | Uses C's served-origin test instructions. |
| FR-011-B | B | Provide repeatable seed-to-cloud readiness validation via retained skills and hygiene. | Reuses FR-003-B and FR-008-B. |
| FR-011-C | C | Test Hosted Ready, retry, fallback, and unavailable consumer states from a served origin. | Exercises D contracts and portal independence. |
| FR-011-D | D | Test Vercel healthy/unhealthy/mismatched/CORS-blocked paths and the here.now portal during intentional Vercel outage. | Produces final FR-008 release evidence. |

## Retained skill architecture

| Skill | Retain | Planned responsibility | Explicit non-responsibility |
| --- | --- | --- | --- |
| `merit-deploy-vercel` | Yes | Vercel deployment plus health, version, CORS, asset, and browser-readiness verification | Marketing publication and consumer UI implementation |
| `merit-portal` | Yes | here.now portal publish and independent availability evidence | Vercel runtime verification |
| `merit-hygiene` | Yes | Aggregate receipts, validate documentation/IAR, and fail incomplete release evidence | Duplicate HTTP/version checking |
| `merit-surface` | Yes | Discover correct MERIT repositories/surfaces when paths are unclear | Deployment behavior |
| Shared internal checker | Yes, internal only | Execute normalized availability/compatibility checks | Become a new public-facing skill |
| New availability skill | No | N/A | Avoid skill proliferation |

No existing skill is deprecated before a read-only catalog audit identifies real overlapping behavior, maps every caller to the retained skill, and records migration guidance.

## Public runtime and consumer behavior

### Runtime contract

`merit-prod` must return a documented public response equivalent to:

```json
{
  "status": "ok",
  "service": "merit-workbench",
  "workbenchVersion": "0.4.0",
  "deploymentId": "immutable-deployment-id",
  "buildSha": "source-revision",
  "deployedAt": "ISO-8601 timestamp"
}
```

The response uses `Cache-Control: no-store`. `0.4.0` is the observed reference only; it becomes the consumer pin only after inventory verifies it represents the deployed artifact.

### Consumer states

| State | Trigger | Required public behavior |
| --- | --- | --- |
| Checking | Bootstrap begins | Brief neutral progress; no hosted-success claim |
| Hosted Ready | Health, exact version, remote asset, and initialization pass | Hosted workbench plus verified version/deployment details |
| Demo Fallback | Network, CORS, module, initialization, or compatibility failure | Interactive local demo labeled offline; reason, retry, portal link |
| Runtime Unavailable | Fallback cannot initialize | Clear error, retry, and portal/status guidance |

## Cloud-plane implementation

### Vercel / merit-prod

1. Deploy health/version metadata alongside the workbench artifact.
2. Bind `workbenchVersion` to the actually deployed artifact.
3. Configure approved consumer origins and verify their browser behavior.
4. Treat health schema, module delivery, and complete initialization as release gates.
5. Preserve timestamped deployment evidence for the consumer cloud report and IAR.

### here.now portal

1. Keep public marketing content in `merit-demo/portal/`.
2. Publish that folder independently; do not import or call Vercel during build/page render.
3. Explain the hosted versus offline-demo distinction without overclaiming runtime health.
4. Verify public URL, assets, and links during an intentional Vercel outage.

## Consumer documentation deliverables

| Artifact | Required content |
| --- | --- |
| `merit-demo/docs/merit_demo_usage.md` | Setup, `.cursor` validation, local HTTP run, hosted verification, fallback, portal journey, troubleshooting |
| `merit-demo/docs/merit_demo_design.md` | Three-plane architecture, boundaries, version policy, state model, ownership |
| `merit-demo/docs/merit_demo_cloud_report.md` | Evidence table, deployment checks, outage outcomes, known gotchas, release recommendation |
| This IAR | FR register, owner zone, acceptance method, evidence links, status, remediation |
| MERIT template/blob | Reusable minimal templates and IAR IDs for future consumer repositories |

## Test and release gates

| Scenario | Expected result | Evidence FRs |
| --- | --- | --- |
| Fresh seed | Required skills/rules are found and seed receipt is truthful | FR-001-A, FR-002-A |
| Healthy compatible runtime | Hosted workbench initializes and shows verified version/deployment | FR-003-D, FR-004-C |
| Vercel outage | Interactive fallback works; portal remains accessible | FR-005-C, FR-006-C, FR-007-D |
| Version mismatch | Hosted runtime is rejected with clear fallback reason | FR-004-B, FR-004-C |
| CORS or remote asset failure | No spinner loop; fallback and retry operate | FR-004-D, FR-005-C |
| Portal independence | here.now marketing renders while Vercel is down | FR-006-D, FR-007-D |
| Missing/stale receipt | Hygiene gate blocks release evidence | FR-008-B |
| Skill audit | Retained-skill inventory maps all consolidation/deprecation decisions | FR-009-B |

## Execution order after review approval

1. Read-only inventory of `merit-demo`, installed `.cursor` content, MERIT skill catalog, Vercel setup, and here.now state.
2. Harden the shared checker, receipts, templates, and hygiene behavior within retained skills.
3. Establish the Vercel health/version/CORS contract.
4. Implement consumer runtime state handling, local fallback, and status details.
5. Build and publish the independent portal.
6. Update consumer documentation, link this IAR, and collect acceptance evidence.
7. Run the hygiene release gate.

## Approval boundary

Creating this IAR does not approve skill deletion, consolidation, runtime changes, portal publication, or deployment. The next implementation action is the read-only inventory described above.
