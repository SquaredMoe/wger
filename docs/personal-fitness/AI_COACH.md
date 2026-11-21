# AI-assisted training + nutrition: v1 operating design

**Stage:** design only; no automatic live wger access and no background execution yet.

## Read-only sources through official wger >= 2.7 API / MCP

- Nutrition diary: daily calories, protein, carbohydrates, fats and fiber against configured goals.
- Weight: use `measurement` and the `body_weight` metric type; do not assume the legacy `weightentry` unit behavior.
- Other measurements: waist circumference (custom), body-fat estimate only if measured consistently.
- Workouts: completed session dates, exercises/sets/reps/weight, training volume, and personal records.
- Recovery: optionally sleep, steps, energy, soreness; flag if missing rather than inventing.

## Daily interaction (2–5 min)

1. Log meals in wger; verify package nutrition labels / portion estimates for local Lebanese foods, because food database coverage varies.
2. Log sets/reps/weights after each exercise; optionally rate the session and record RIR/effort.
3. Record morning weight before breakfast on 3+ consistent days per week.
4. Record once-weekly waist measurement, and note unusual bloating and sleep disruptions.

## Weekly coaching report (Saturday, Asia/Beirut)

Include date range, data completeness, and explicit uncertainty.

| Section | Inputs | Proposed outputs |
|---|---|---|
| Adherence | planned vs completed workouts; nutrition diary days | realistic consistency score and missing days |
| Weight | last 7-day average vs previous average; note sparse days | direction and uncertainty; not a single-day verdict |
| Waist | same-site weekly measurement | direction; don't claim spot reduction |
| Nutrition | calorie mean, protein consistency, fiber, added sugar context | simple food/portion substitutions; no invented nutrition |
| Training | sets, effort, volume and repetition performance | add/reduce sets or weight conditionally |
| Recovery | sleep/energy/soreness/discomfort | rest or deload suggestions |
| Next week | current goals + trends | one or two proposed changes, never unapproved writes |

## Decision policy

- First 14 days = baseline; do not react to a single weight or missed session.
- Evaluate 2–4-week trends and workout performance together. Do not assume weight loss is always desirable.
- Avoid drastic restriction or trying to burn fat from one body area. Preserve protein adequacy and strength while pursuing recomp.
- Any change to macro/calorie targets, programmed weights, meal plans or training frequency requires **explicit user approval** before write access.
- AI should not diagnose thyroid issues or modify prescribed medication. Treat symptoms and abnormal labs as reasons for clinician review, not automatic diet overrides.
- Data privacy: no raw medical notes, personal fitness data or API credentials committed to public GitHub. Avoid public MCP with shared static tokens. Restrict AI access to least privilege, log changes and maintain a restore path.

## Suggested initial 4-day split (template, not yet personalized)

- Day 1: upper-body strength (horizontal push/pull, shoulder support, arms).
- Day 2: lower-body strength (squat pattern, hinge pattern, calves, core).
- Day 3: upper-body hypertrophy (vertical push/pull, back, chest, delts, arms).
- Day 4: lower-body hypertrophy (single-leg, hinge/accessory, core).

Individualize exercise, volume and intensity after confirming training age, injuries, goals, height, weight and age. Do not prescribe calories or a program as personalized before collecting those inputs.

## First AI review prompt (for an assistant connected to your wger account)

"Read my last 14 days of nutrition diary, workout sessions, and body weight/waist measurements from wger. Do not modify any record. Summarize missing days, calorie/protein adherence, completed training sessions, changes in rolling weight and waist, exercise performance and recovery. If data is incomplete, state exactly what is missing. Give 2 evidence-based, modest adjustments for next week and ask for my approval before applying any changes. Use Asia/Beirut local dates, kg and cm."

## Integration path

**Phase A:** use native wger app and API, log data for 2 weeks.  
**Phase B:** deploy official wger MCP bridge in a secured private environment. Verify API compatibility with wger >= 2.7 and read-only scopes first. Test against non-sensitive dummy records.  
**Phase C:** automate weekly report generation only after a compatible MCP client / approved remote connection is configured.  
**Phase D:** add optional write tools for workouts/plans after audit trails, confirmation and successful backup/restore drills.

## Acceptance tests before claiming the system works

- [ ] Docker compose config validates and every required container healthy.
- [ ] Browser sign-in with user-created password works on host.
- [ ] Default admin credential, JWT keys, `SECRET_KEY`, DB passwords are rotated.
- [ ] Exercise list and ingredient search work.
- [ ] A test workout, meal, body weight and waist measurement persist after restart.
- [ ] PowerSync mobile auth/sync validated on Android over secure HTTPS, if remote access configured.
- [ ] Database + media backups exist and a restore test succeeds.
- [ ] MCP access is authenticated and correctly scoped; a read-only test cannot write.
- [ ] Weekly report matches raw entries on a small, manually checked sample.
- [ ] No health or login secrets appear in Git history, logs or dashboard exports.
