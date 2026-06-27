# FR-13 Skillchain Planner - Planning Questions

> **STATUS: RESOLVED.** All answers below have been folded into the FR-13
> acceptance criteria in `requirements.md`. Data source confirmed: the SkillChains
> addon (`scripts/Skillchains/skills.lua` + `Skillchains.lua`) provides WS→property
> data, combination rules, rank 3→4 extensions, magic-element mapping, the timing
> window formula (`delay + 8 - step`, default delay 3s), and the action-packet
> mechanism for WS-landed / skillchain detection.
>
> **Note on Q6c (CONFIRMED)**: All player `weapon_skills` use the 3s default delay.
> Longer delays in the data (5-8s) are only on `monster_abilities` (trust/NPC TP
> moves like Iainuki/Amatsu — which we never issue) and SCH Helix `spells` (delay=5,
> relevant only if Immanence is incorporated). The imported `skills.lua` already
> carries those values, so no manual overrides are needed.

Open questions to resolve before implementing the automated skillchain planner.
Answers will be folded back into the FR-13 acceptance criteria.

## 1. Skillchain Property Data Source

The planner needs to know each weapon skill's skillchain properties (e.g.,
Savage Blade = Scission/Detonation). 

- **Q1a**: Is this data available in Windower's `res.weapon_skills`, or do we need
  to build/ship a custom WS→skillchain-property lookup table? 
  We can import the data from the Skillchains addon. I've included the files in the scripts folder.
- **Q1b**: If we ship a table, how do we keep it current with new weapon skills?
  Weapon Skills don't update very often. I don't think they've updated since the Voracious
  Resurgence added Prime Weapons.
- **Q1c**: Same question for skillchain combination rules (which two properties
  combine into which skillchain element, and the rank 3 → rank 4 extensions).
  Check the Skillchains folder. I believe that information is in there. If it is not,
  follow back with me.

## 2. Element Argument Semantics

- **Q2a**: What values are valid for `<element>`? Just the named skillchain
  elements (Light, Darkness, Fusion, Fragmentation, Gravitation, Distortion,
  Liquefaction, Induration, Detonation, Scission, Impaction, Reverberation,
  Compression, Transfixion)? Or only the "goal" elements?
  Just the goal elements, which should be based on the element that we will be magic bursting.
- **Q2b**: Does `//box skillchain plan light` mean "the chain must CLOSE on Light"
  or "produce Light at any point"?
  It must CLOSE on light, but it can also produce light multiple times.
  The priority is to close on light with the highest damage weapon skillt that results in
  light coming last. Note: Some weapon skills are "terminal," meaning that they end a
  skillchain. All level 4 skill chains are terminal. Keep this in mind.
- **Q2c**: If the requested element is not achievable with current party WS, should
  the planner: (a) report failure, (b) suggest the closest achievable chain, or
  (c) pick the highest-damage achievable chain instead?
  A

## 3. Controller / Participant Roles

- **Q3a**: Which box runs the command — does it need to be a specific character
  (tank/puller), or can any box issue it?
  Anyone can issue the command, and it builds a queue of send character weapon skill and 
  wait commands to run for the execute function. The plan function just does a
  windower.addtochat function and outputs the shorthand for each character and
  each weapon skill. You can get the shorthand from the titles in macro book 23 
  and 24 in the data folder of Macro Editor.
- **Q3b**: Does the controlling player participate in the chain, or only direct the
  other boxes?
  If they can, yes. If they aren't able to, then no. No one is excluded.
- **Q3c**: How is target consistency ensured across all participants? Use `<bt>`
  (last claimed by party)? Require all boxes target the same mob first?
  Use <bt>. Ideally the party should all be on the same mob.

## 4. TP Thresholds

- **Q4a**: Fire at 1000 TP minimum, or wait for higher TP (WS damage scales to
  3000)? Configurable threshold?
  If the user fires the command with the execute function, and a character can execute
  a weapon skill in the chain, do so.
- **Q4b**: Should the planner account for TP Bonus gear/traits (some jobs WS at
  effectively higher TP)?
  Nothing so granular. What you're looking at is the total "percent modifier" and
  TP bonus. As an example, Tachi Fudo uses 80% strength and gives and 8x bonus
  at 3000 tp. The Prime weapon skill for GK uses some other percentage, but I
  remember that the tp modifier is 11x at 3000 tp. If you can get the character's
  stats and math out the modifier, great. If not, let me know and I'll work on it.
  You CAN use the actual formula if you want, but leave out information that
  you would have trouble getting from windower.
- **Q4c**: Does plan-only require current TP, or does it plan theoretically based on
  who COULD weapon skill regardless of current TP?
  It absolutely does require current TP.

## 5. Weapon Skill Availability (FR-13b)

- **Q5a**: `windower.ffxi.get_abilities().weapon_skills` returns WS for the LOCAL
  player only. How do other boxes report their available WS — IPC request/response,
  or written to the shared file (like job/HP data)?
  Written to the shared file when they log in, change job, or change weapon type equipment. 
  Do not rewrite for armor changes. Just job or weapons.
- **Q5b**: How often is WS availability refreshed (on job change, on demand, cached)?
  As stated above, job change, log in, weapon equipment change. (Including ranged weapons.)

## 6. Execution Timing & Coordination (execute command)

- **Q6a**: Skillchains require each WS to land within the skillchain window
  (~2-6s after the previous). How does the planner coordinate timing — fixed delays
  between steps, or wait for confirmation that each WS landed?
  Check in the Skillchains folder for answers to that. If a weapon skill misses,
  try to calculate an alternative answer and pivot if you can.
  Commands should not be sent until the previous weapon skill has gone off,
  though you can store the curent planned skill chain somewhere while running the 
  wait commands.
- **Q6b**: How do we detect that a WS actually landed (action packet, TP drop,
  fixed assumption)?
  I don't know, that's a good question. Look in the Skillchains addon and see if there
  is an answer there. If not, circle back.
- **Q6c**: What is the delay/window between steps, and is it configurable?
  Again, check skillchains. Some weapon skills have greater delays (notably the trust
  Iroha has a weapon skill that has a significantly longer delay.)

## 7. Magic Burst Coordination (FR-13e, h)

- **Q7a**: After a WS closes a skillchain, there's a magic burst window (~3-6s).
  How does the planner signal casters to nuke, and with what timing?
- **Q7b**: What spell does a burst caster cast — the highest-tier nuke matching the
  skillchain's element? How is "highest available" determined (reuse FR-8 nuking
  logic, or simpler)?
  Reuse FR-8 nuking logic. Be aware of cast time. Start casting early if necessary.
- **Q7c**: Skillchain elements map to specific magic elements for bursting. Do we
  need a skillchain-element → magic-element mapping table?
  Yes. I believe this exists in the Skillchains addon that I placed in the scripts
  folder.

## 8. Abort Conditions (execute command)

- **Q8a**: Confirmed: abort if target dies. What else triggers an abort?
  - Target changes / loses claim?
  - A participating character disconnects mid-chain?
  - A character gets stunned/silenced/interrupted?
  - Chain step fails (WS whiffs / out of range)?
  If the target dies or we lose claim, then we should definitely abort. If any of the
  other problems arise, we should try to pivot and finish the skill chain while
  working around the problem.
- **Q8b**: On abort, should remaining queued steps be cancelled cleanly, and should
  the user be notified why?
  On abort the remaining steps should be cancelled, but there shouldn't be a notification.

## 9. Chain Length & Optimization

- **Q9a**: Max chain length — as long as possible using all full-TP characters, or a
  cap? (Game allows extended chains but timing gets harder.)
  There is probably a point where it becomes impossible to continue chaining. Look up
  the window for each successive skill chain. If the window is a single second or less,
  then we should stop there. (i.e. if we did "another" weapon skill, and the window to get it
  right would be a second or less, we don't do that weapon skill.)
- **Q9b**: When optimizing for "total damage" (FR-13c), do we have damage estimates
  per WS, or is this based on heuristics (e.g., known high-damage WS list)?
  We use the weapon skill damage formula with the values for the individual weapon skill
  (which we may need to supplement when we import the skills from Skillchains) and any
  easily obtainable values from windower. Values that we can't easily get we ignore.

## 10. Pet Jobs (FR-13f, g, i)

- **Q10a**: BST pet WS — how is pet TP / Ready availability checked for other boxes?
  We are not checking pet TP. We are ignoring the pet TP modifiers. Ready is a cooldown
  and the timers we create for a character are available on every box. We can check
  the timers for the beastmaster character to see if they have a charge available for Ready.
- **Q10b**: PUP automaton — defer to research during implementation, or scope out
  now? (Currently marked "implement if feasible.")
  Defer to research later. I don't have a puppetmaster that I can really test with yet, anyway.
- **Q10c**: SMN dual-burst (FR-13i) — defer to implementation testing, or scope out
  now?
  Uh... I changed how my party works, so while having summoners burst is a fun idea,
  let's just leave summoner bursting as a single magic burst. It should still be
  prioritized for a burst later in the chain if feasible.

## 11. Alliance TP Collection (FR-13a)

- **Q11a**: Default fallback timeout value for the `reporttp` IPC collection?
  I don't know. Let's table Alliance integration until we make the alliance upgrade.
- **Q11b**: Does plan-only also do alliance TP collection, or only execute?
  Tabled until we do the alliance upgrade.
- **Q11c**: Is alliance support for the skillchain planner in scope for the first
  implementation, or party-only first (with alliance as a follow-up)?
  Party only first.

## 12. Positioning / Range

- **Q12a**: Melee WS require being in range of the target. Does the planner assume
  all participants are positioned correctly, or attempt any range validation?
  Assume all participants are positioned correctly.
