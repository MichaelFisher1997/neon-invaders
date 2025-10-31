# Analytics & Telemetry Plan

## Objective
Instrument the game to track player progression, economy health, and monetization funnels while respecting privacy regulations.

## Instrumentation Targets
- Wave progression (wave reached, time spent per wave tier, failure reasons).
- Credit economy (credits earned/spent per session, multiplier tiers hit, shop conversions).
- Cosmetic usage (equip rates, purchase funnels, favored color/shape combos).
- Upgrade interactions (levels purchased, time to max, upgrade screen visit frequency).
- Monetization events (premium currency purchases, booster activations, ad engagements).

## Implementation Steps
1. Select analytics provider (Amplitude, GameAnalytics, Firebase) with Lua/LÖVE support or lightweight REST API.
2. Build an asynchronous telemetry module with batching and offline queue for desktop/mobile platforms.
3. Add opt-in consent flow (especially for GDPR/CCPA) and anonymize player IDs.
4. Configure dashboards tracking KPIs: retention (D1/D7/D30), ARPDAU, conversion funnel, difficulty breakpoints.
5. Establish alerting (e.g., Slack webhook) for anomalies like credit spikes or wave completion drops.

## Privacy & Compliance
- Document data schema; avoid collecting PII.
- Provide in-game toggle to disable analytics and clear stored data.
- Update privacy policy and store listing disclosures prior to launch.

## Done When
- Telemetry events flow reliably in staging, dashboards are live, and product/design have access to actionable metrics.
