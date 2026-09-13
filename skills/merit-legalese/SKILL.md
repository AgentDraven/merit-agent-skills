---
name: merit-legalese
description: Generate and maintain MERIT consumer legal, privacy, registration, and terms pages from the vault standard. Use when a consumer repo needs legal.html, terms.html, privacy boundaries, payment disclosures, minor-participant language, or a reusable legalese baseline.
---

# merit-legalese

Use the vault standard templates in `merit-private-vault/templates/consumer-static/portal/` as the canonical baseline. Keep consumer pages in `portal/legal.html` and `portal/terms.html`; publish only the `portal/` surface.

## Rules

- Start from the standard templates; do not copy product-specific financial, medical, or other regulated language into unrelated consumers.
- Replace every `{{PLACEHOLDER}}` with verified product facts before publication.
- Keep provider boundaries explicit: payment-card data, provider credentials, subscriber identity, and entitlement records belong to their owning provider systems.
- For minors, state the actual guardian/consent and age policy. Never imply that a child’s data is collected without the operator’s intended consent path.
- Describe prices, discounts, refunds, cancellation, free add-ons, and opt-out behavior exactly as implemented. A `$0.00` add-on must not imply a charge.
- Do not invent governing law, arbitration, liability caps, refund rights, or regulatory claims. Mark missing legal decisions for operator/legal review.
- Do not place secrets, API keys, payment-card data, or private vault material in legal pages or public source.
- Include links between `legal.html` and `terms.html`, a contact address, an effective date, and `MERIT Powered`.

## Workflow

1. Inventory existing consumer legal pages and extract only reusable boundary language.
2. Copy the vault templates into the consumer’s `portal/` directory.
3. Fill product, provider, participant, payment, cancellation, and contact placeholders from the consumer IAR/config.
4. Run a placeholder scan and check that no secrets or stale product claims remain.
5. Render or browser-check both pages, then obtain operator/legal review before publishing.

## Required checks

```text
[ ] No {{PLACEHOLDER}} tokens remain
[ ] legal.html and terms.html exist under portal/
[ ] Legal ↔ Terms links resolve
[ ] Payment provider and card-data boundary is accurate
[ ] Minor/guardian policy is accurate for this consumer
[ ] Pricing, discounts, free add-ons, cancellation, and refunds match implementation
[ ] No credentials or private vault references are exposed
[ ] MERIT Powered footer is present
[ ] Operator/legal review recorded before publication
```
