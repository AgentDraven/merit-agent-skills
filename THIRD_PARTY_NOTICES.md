# Third-party notices — merit-agent-skills

**For operators:** include this section (adapted) in your product **`portal/legal.html`**, **README**, or **`THIRD_PARTY_NOTICES`** file.

---

## MERIT Agent Skills (merit-agent-skills)

Portions of this product’s agent workflows, CLI recipes, and configuration scaffolds are derived from or compatible with **[merit-agent-skills](https://github.com/AgentDraven/merit-agent-skills)**.

```
Copyright 2026 MERIT LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use these files except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

**Trademarks:** MERIT, merit-agent-skills, merit-live, and MERIT Powered are trademarks of MERIT LLC. This notice does not grant trademark rights beyond describing origin.

**Not included in Apache grant:** merit-private-vault, certification attestation authority, production meritstore/meritsubs operator credentials, or paid PAR packages (`@1.0.x`) — those require a **meritstore** tenant and applicable subscription terms.

---

## meritutils (PAR CDN)

Browser packages such as `merit_workbench` and `journal` are loaded from **`pkg-meritutils.vercel.app`** under separate provider terms. Production pins and entitlements are scoped to your **`consumer_id`** on your Vercel host.

---

## Operator customization

Replace `{{PRODUCT_NAME}}` and `{{OPERATOR_LEGAL_ENTITY}}` in your legal pages. White-label branding is configured in `cfg/branding.json`; **MERIT Powered** attribution in the footer remains required when MERIT platform components are used.
