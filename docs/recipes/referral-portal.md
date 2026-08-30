# Referral portal recipe (FR-AFF-OSS-04)

Copyable CTA patterns for consumer `portal/`. Split **join** (program) from **attribute** (checkout referral).

## Join the program

Public cohort join is operator-gated. Prefer the production Portal:

```html
<a href="https://merit-prod.vercel.app/portal/partners.html">
  MERIT Affiliate &amp; Design Partner
</a>
```

Or mailto (same subjects as the Portal):

```html
<a href="mailto:meritlabs@protonmail.com?subject=MERIT%20affiliate%20join">Join as MERIT affiliate</a>
<a href="mailto:meritlabs@protonmail.com?subject=MERIT%20design%20partner%20join">Join as design partner</a>
```

Do **not** deep-link `/store/meritsubs/register?plan=affiliate-join` (or raw meritstore equivalent) as if self-serve — the gateway redirects that path to partners.html.

## Attribute referrals (consumer portals)

Share a provisioned app register URL with your code (gateway rewrite → meritstore):

```html
<a href="https://merit-prod.vercel.app/store/YOUR_CONSUMER_ID/register?referral=YOUR_CODE&utm_source=portal&utm_medium=cta&utm_campaign=partner_referral">
  Sign up with my referral
</a>
```

Legacy `?affiliate=` still works on meritstore register.

## Hosted program landing

**Start here (plain language):** [merit-prod.vercel.app/portal/partners.html](https://merit-prod.vercel.app/portal/partners.html).

Provider-side explainer also lives on **meritstore** `portal/` (here.now) — not vault (FR-FOCUS-003).

## Non-goals

Do not embed Square keys, partner payout destinations, or admin JWT minting in portal HTML.
