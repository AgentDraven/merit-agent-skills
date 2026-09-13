# MERIT public brand system

Status: public OSS standard
Owner: `merit-agent-skills`
Private governance source: `merit-private-vault/docs/IAR/branding/MERIT_FOOTER_STANDARD.md`
Last reviewed: 2026-09-12

This is the reusable, non-secret presentation standard for MERIT OSS portals, examples, and skill-generated public surfaces. Consumer products may add their own accent or product identity, but MERIT-powered surfaces should remain recognizably MERIT.

## Visual language

- Canvas: near-black `#08090b`.
- Panels: deep charcoal `#111419` with border `#292e35`.
- Text: near-white `#f5f7f8`; secondary copy `#a7afb8`.
- Primary accent: gold `#f4bd4b` for CTAs, links, and product headings.
- Signal accent: neon green `#52ff28` for eyebrows, tags, status, and capability markers.
- Supporting accent: cool blue-gray for quiet contrast and evidence-oriented surfaces.
- Shape: generous spacing, rounded cards, thin dividers, and responsive stacking.
- Hierarchy: brand, one clear headline, one supporting sentence, and one obvious next action. Put technical detail one click deeper.

## OSS portal requirements

1. Keep marketing content in `portal/`; never place credentials or private operator policy there.
2. Load or reproduce the tokens above and keep the dark MERIT canvas, card, divider, and responsive rules.
3. Use `MERIT Powered` in the footer when MERIT platform components or rails are used.
4. Use the footer order: Legal &amp; Privacy · Terms · Security, then small legalese, positioning copy, status, and contact.
5. State evidence boundaries honestly: health is not authorization, persistence, entitlement, or production readiness.
6. Keep product-specific branding subordinate to clear MERIT attribution when the surface is MERIT-powered.
7. Version changed shared stylesheets and images with a query string such as `?v=YYYYMMDD-N` or use immutable filenames so browsers cannot retain an older brand system.

## Starter CSS tokens

```css
:root {
  --ink: #08090b; --panel: #111419; --line: #292e35;
  --gold: #f4bd4b; --green: #52ff28;
  --text: #f5f7f8; --muted: #a7afb8; --charcoal: #30343b;
}
```

Use the corporate portal as the reference implementation. Its private working copy is `merit-private-vault/portal/merit-company-site/styles.css`; this public document contains the portable rules and no private data.

## Source-of-truth boundary

- Public reusable guidance: this file and `skills/merit-portal/SKILL.md` in `merit-agent-skills`.
- Private canonical governance, legalese wording, and acceptance checklist: `merit-private-vault/docs/IAR/branding/MERIT_FOOTER_STANDARD.md`.
- Product-specific portal copy and assets remain in each consumer repository's `portal/` folder.

Shared CSS or image changes must include a cache-busting/immutable-asset update in the same release. A visually correct local file is not sufficient if an existing hosted tab can still load an older asset.

When the standard changes, update the private IAR first, then update this public document and the portal template/skill guidance. Do not copy private credentials, tenant data, or operator-only policy into OSS.
