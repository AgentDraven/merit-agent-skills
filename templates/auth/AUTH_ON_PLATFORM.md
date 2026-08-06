# Auth on a MERIT app (FR-MPD-14)

## Default (platform rails — Proven at GA)

1. Create / dinner lands your app on `merit-prod` `/apps/<app>/play`.
2. Activate the store (self-serve):

```text
POST https://merit-prod.vercel.app/api/meritstore/v1/tenants/<app>/activate
{"template":"free-community","display_name":"Your App"}
```

3. Members register with **email + handle** at  
   `https://merit-prod.vercel.app/store/<app>/register`  
   Free convert grants community entitlement; **no operator** and no local Supabase required.

## Optional BYOK session (own Supabase)

When you set `supabase_*` in `.merit_launch.ini`:

1. Apply `templates/auth/supabase_rls_profiles.sql` on your project (SQL editor).
2. Wire browser client with anon key (keys never in git).
3. Use Supabase Auth for signup / login / password reset; keep `consumer_id` on profile.

Platform meritsub and store continue to meter identity and SKUs via the gateway.
