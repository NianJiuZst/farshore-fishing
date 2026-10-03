# Float bite research and release model

Checked 2026-10-03. Scope: the 44-species, 12-location float-based game. This is a research and design specification; numerical values below are proposed game tuning, not measured fish behavior. No production code was changed for this document.

## Decision

Make the float show changes in the load and direction of the rig. The player reads a coherent sequence against the water's normal rhythm and strikes while the fish holds the bait. A float lifting, sinking, or moving sideways is an observation, not a universal guarantee that a fish can be hooked. Do not guarantee a take after a countdown, assign each species one immutable signal, or require every encounter to pass through the same tap-then-take sequence.

The game should support three useful takes: a sustained lift, a sustained draw-down, and directed lateral travel. They can begin directly or after exploratory touches. Some touches end without a take. A true take may also be small but decisive; do not teach players always to wait for the largest movement.

## What the sources actually support

All sources are primary material published by established tackle manufacturers or the Recreational Boating & Fishing Foundation's Take Me Fishing program. The linked article/PDF content was inspected, not just its title. The Daiwa and Shimano Japanese passages were additionally opened in the cloud browser; Daiwa's “棒ウキ” panel was expanded. The Japanese points below are paraphrases. No claim of having watched the embedded Shimano video is made.

| Source | Supported finding | Boundary |
| --- | --- | --- |
| [Drennan: The Double Bulk Rig](https://www.drennantackle.com/double-bulk-rig/), Jon Arthur, 21 April 2017 | A second group of shot near the hook makes changes particularly readable. The same bottom-oriented rig can rise or sail away. Bream, carp, and tench are examples; movement can also show a bait intercepted during descent. Shot location and hooklength matter. | A rig-specific account, not evidence that every bream lifts or every predator sinks. |
| [Drennan: Driftbeaters and the Lift Method](https://www.drennantackle.com/pdf-articles/driftbeaters_peter_drennan.pdf), Peter Drennan, especially PDF pp. 2–3 | A carefully balanced anchor shot near the bait can produce an upward indication when disturbed. Increasing hook-to-shot distance shifts the balance toward disappearing floats. Fish brushing the line can cause false indications. Wrong depth changes the float's resting height. | This is a particular anchored stillwater method. Its mechanics must not be imposed on every water layer or marine rig. |
| [Drennan: The Art of the Lift Method](https://www.drennantackle.com/the-art-of-the-lift-method/), 4 May 2016 | A successful take can begin as a quiver and develop into a steady rise or a plunge. Surface tow itself can pull a float under. Hooklength and location change the presentation. | “It went under” is not sufficient by itself to distinguish fish from environmental force. |
| [Drennan: Bodied Wagglers](https://www.drennantackle.com/pdf-articles/bodied_wagglers_peter_drennan.pdf), Peter Drennan, especially PDF p. 3 | Tench and crucians may give preliminary indications; fin/line contact can produce a short sideways curtsey. Float shape, exposed tip, line management, and wind affect what is readable. | Short motions can be exploratory or line contact, but this source does not establish that all small motions are false. |
| [Shimano: 実釣編7『アタリをとらえて合わせよう』](https://fish.shimano.com/ja-JP/content/fishingstyle/article/isobohatei/2021/210010/index.html), 8 May 2017 | In sea float fishing, takes range from an abrupt disappearance to a slight movement. The article advises reacting to the detected take because hesitation can let a fish spit the bait. | Its assertive advice concerns recognized takes in that technique. It does not erase wind, current, or rig movement described by other sources. It contradicts a universal “wait until the float is fully underwater” rule. |
| [Daiwa: 銀狼 STYLE, 棒ウキ](https://www.daiwa.com/jp/brand/product-brand/ginro/style) | A sensitive stick float registers subtle changes; removal of a heavy bait can make the tip rise. Pulling the mainline can sink/tilt the float; line handling and current matter. | A rise may tell the angler that bait is gone. A float cannot directly certify that a hook is in a fish's mouth. |
| [Daiwa: Beginner tackle, ウキ](https://www.daiwa.com/jp/beginner/tackle/float) | Float size, shape, and shotting trade sensitivity against visibility/stability. Too much buoyant body exposed increases resistance and can cause a fish to drop bait. | Bigger movement is not a universal measure of fish size or readiness. |
| [Take Me Fishing: Traditional Fishing Floats: The Bobber](https://www.takemefishing.org/blog/november-2015/traditional-fishing-floats-the-bobber/), Andy Whitcomb, 30 November 2015 | Bites can appear as twitches, disappearance, steady movement, or a halt in a drifting float. Round floats and narrow floats show different behavior. Slip floats let an angler present bait deeper than a fixed castable rig. | Introductory examples, not fixed timing thresholds or a species-to-pattern lookup. |
| [Drennan: Fish the Slider](https://www.drennantackle.com/martin-bowlers-top-tips-8-fish-slider/), 28 July 2017 | After landing, the rig sinks, the stop reaches the attachment, and the float cocks before the droppers establish its final level. Measuring depth is part of making indications readable. | Normal settling is not a bite. This does not establish the practicality of every extreme depth represented by the game. |

### Reading the directions without making false rules

- **Lift / 送漂:** a reduction in the load supported by the float can raise it. A fish supporting a bait and nearby suspended shot, or disturbing a deliberately balanced bottom rig, can cause this. Bait loss or changed depth can also raise the resting tip. Do not write “the fish swims upward, therefore the float always rises”: slack and shot geometry can prevent or alter transmission.
- **Sink / 下沉、黑漂:** extra downward line load can submerge the float when a fish carries bait away. Tow, line tension, or the rig settling can also pull it down. A sink should develop differently from the surrounding wave motion if it is to be a readable game take.
- **Lateral travel / 横移、走漂:** the float can follow a bait-carrying fish. Water also carries the entire rig. Compare direction, speed, and acceleration with the established drift; a stop or change in drift can be informative too.
- **Exploration / 试探:** separated touches may deflect and recover without sustained displacement. Their order and spacing should look like actions, not visual static. A brief contact can end, repeat, become a take, or be bypassed by a direct take.
- **Environment / 水流、波浪:** use smooth shared waves and a persistent current vector. They change the reference position and angle; they must not randomly switch the hidden hook state. Real waves are not perfectly periodic, but coherent correlated motion is a useful readable simplification.

The distinction is causal: the float displays force on the rig, while hooking depends on the hook being held and the line transmitting a strike. These two facts are related, but are not identical.

## Proposed coherent game model

### 1. Keep one source of truth

The authoritative simulation owns bait contact, bait possession, fish motion, supported shot load, line slack, and the float's target pose. Presentation reads that pose only. Use the existing fixed simulation step and encounter seed so frame rate and pause/resume cannot change the outcome.

Suggested small internal state:

- `bait_state`: available, touched, held, released, lost
- `fish_motion`: approach, mouth, lift, descend, turn, carry, depart
- `rig_profile`: suspended, near_bottom, bottom_lift; chosen from the intended presentation
- `line_slack`, `load_down`, `load_supported`, `pull_direction`, `pull_speed`
- `float_y`, `float_xz`, `float_tilt`, and their velocities

These names are implementation suggestions, not player-facing labels. Existing `float_dip`, `float_lift`, `float_drag`, and `float_tilt` can remain the rendering interface.

### 2. Generate an encounter, not a guaranteed timer

Choose a short sequence of actions at cast/encounter time, with seeded variation within a family. For example:

| Family | Coherent visible sequence | Possession and result |
| --- | --- | --- |
| Tentative bottom pickup | tap, recover, pause, slower upward travel, hold/turn | Touches need not be held; the developed lift can coincide with possession. |
| Confident draw-down | optional single check, smooth accelerated dip, submerged travel | A direct take is allowed. No mandatory preliminary nibble. |
| Lateral carry | slight lean, sustained movement in one direction, possible dip | A direction/speed change relative to current signals carried bait. |
| Soft take | one small decisive draw or rise that pauses off the normal level | Fish already holds bait despite modest amplitude. Preserve a readable interval. |
| Reject and revisit | one or more touches, return to baseline, quiet gap, new attempt | No automatic take at the end of the first touches. |
| Contact only | brief sideways bend, recovery | Fin/line contact; striking produces an empty retrieval. |
| Release | a held motion relaxes back toward the normal level | Possession ends; no catch once the hook is free. |
| Bait loss, optional | pecks, unloading, a new higher resting level with no carry | Empty hook; distinguish the completed unloading from a continuing held take. Use sparingly, only if bait loss is represented. |

Action durations are still needed to animate motion; that is different from making “N seconds have passed” the only condition for hooking. The sequence should permit retreat, revisit, and direct take. The same species must be capable of more than one relevant family.

A player pressing after the same elapsed time across seeds should not reliably succeed. A player following a clearly readable genuine take should succeed consistently. Avoid a hidden random miss roll after a correct strike; uncertainty should primarily arise from the evolving bait/line state that produces the visible movement.

### 3. Derive motion from loads

Use a damped response toward a load-dependent equilibrium rather than independent per-frame random positions:

`target_height = resting_height + supported_load * lift_gain - downward_load * dip_gain`

`target_position = drifting_baseline + transmitted_fish_pull`

Tilt should agree with horizontal pull. A lift should expose more of the banded tip relative to the local water surface; a dip should progressively cover it. Use smooth acceleration, visible pauses, and a recover phase. Maintain position/velocity continuity when an encounter changes phase. Do not reset the float to baseline just because an internal state enum changes.

Motion must be measured against the local waterline: moving the float and water up together is a wave, while exposing another band is a change of supported load. The surrounding ripple movement gives players the reference for lateral drift.

**Proposed visual tuning, not real-world measurements:** baseline vertical motion about 3–8% of the visible antenna length; exploratory peaks about 10–25%, followed by recovery; readable takes about 35–80%, with soft-take variants about 15–30% but a distinct pause/direction change. Keep the fish signal perceptible under the largest supported waves. Baseline periods around 2.5–4.5 seconds and separated touch beats around 0.4–0.9 seconds are starting points, not mandatory rhythms. Do not simply apply a higher-frequency sine wave throughout NIBBLE.

**Proposed input tuning:** after a readable genuine take begins, provide roughly 0.8–1.8 seconds for the normal difficulty range, adjusted by family and difficulty. Tune on the smallest supported Android screen and at low frame rate. A short causal lead of about 0.15–0.30 seconds may let the movement become visible before a strong strike is supported. Do not expose these numbers or an exact countdown to the player. A soft take must not require a near-instant reflex to compensate for its smaller amplitude.

### 4. Resolve a fresh strike against possession

A successful hook requires a new press while the hook is held and the simulated line can transmit the strike. A held input from before the take is not a new strike. Striking during mere line contact, before the bait is held, or after release gives an empty retrieval. If a firm take is already visible at the instant possession begins, it should be hittable then; no extra invisible grace delay may contradict the animation.

Do not teach players to wait for swallowing. “鱼正含饵” describes possession; “已经吞钩” or “咬牢后才可提竿” suggests a certainty the float cannot provide. A correct strike starts the fight, whose outcome remains separate.

### 5. Apply rig, depth, species, and place without claiming universality

The repository currently carries `behavior` for fights. That is not evidence of feeding style. Do not use a species-ID hash modulo three as the scientific basis for lift/sink/lateral selection. Species-specific weighting is acceptable as explicitly documented game tuning.

- Start with a bottom pickup bias for the well-supported carp/bream/tench grouping only when using a compatible near-bottom rig. Crucian encounters can weight longer exploration, with occasional direct or soft takes. Preserve other signal outcomes for each.
- All other species can initially use general suspended/near-bottom families selected by the encounter's presentation. A broad “burst/rest/steady” fallback can adjust tempo for variety, but label it gameplay tuning. Do not describe this as researched behavior for each of 44 species.
- Compute rig context from explicit encounter fields, such as actual bait depth, intended near-bottom presentation, water depth, and a calm/current/open-water preset. A species' maximum recorded depth alone does not determine its float indication.
- Calm lake/backwater locations give a small stable reference; channel/river locations give coherent lateral drift; harbor/reef/boat locations add a larger but still readable wave component. Weather can change the shared water motion, not silently decide whether a strike succeeds.
- Near-bottom presentation increases the availability of lift motifs; suspended presentation favors transmitted draw-down/sideways take motifs. Long lines can smooth transmission in the game, but depth must never make the player strike before a signal is visible.
- The always-visible float across deep boat fishing and every bait category is a deliberate game abstraction. No inspected source validates a single conventional float rig for every catalog species, lure, or the full 180 m location range. Say that the game simplifies tackle and time; do not market the model as a complete real fishing simulation.

No extra equipment UI is required for this release: rig context can be automatic and explained once. If the current encounter dictionary does not include depth/presentation, a generic seeded family mix is safer than pretending the species hash encodes physical rigs.

## Chinese help copy

### Short first-use instruction

先看浮漂随水起伏的节奏。轻点后回位，可能只是试探；出现不同于水波的顿沉、持续送漂或定向横移时，及时提竿。小动作也可能是真口，不必等到整支漂沉没。

### Compact permanent help

读漂看变化：试探常会回位，含饵后的动作更连贯。送漂、下沉、横移都可能是鱼讯；别只数秒，也别只等黑漂。

### Expanded optional help

浮漂显示的是线组受力。鱼托起饵和配重，漂可能上升；含饵游走，漂可能下沉或横移。水流、碰线和鱼饵脱落也会改变漂相。先观察这一竿的水波与漂流，再抓住异常动作出现的时机。

### Model disclosure

游戏统一使用浮漂观察鱼讯，并简化线组、水深与时间。不同鱼、饵和水域会改变漂相，没有一种动作能保证中鱼。

### After-action messages

- Early empty strike: “提竿时鱼还未含住钩饵。下次留意试探之后，是否出现连贯的受力变化。”
- Strike after release: “鱼已松口，浮漂正在回位。下次留意动作刚改变的时机。”
- Contact-only strike: “这一竿没有挂住鱼。碰线和水流也会让浮漂动。”

Do not show these explanations before the strike. Do not change the primary button text, color, availability, camera, sound, vibration, overlay, or popup at a hidden transition into a hittable state. Help can be opened manually and must not announce a live take.

## Release acceptance checks

1. Seeded encounters cover all three major take directions, a direct take, a soft take, a reject/revisit, and contact-only motion. A rejected exploration does not inevitably become an immediately hittable take.
2. Across repeated casts of one species, direction and progression vary within its rig context; they are not a fixed identity hash.
3. Pressing while only waves/contact occur cannot hook a fish. A fresh press during a visible held take can; after release it cannot. Holding the button before the take cannot auto-hook.
4. The float signal, the possession interval, and input resolution agree at phase boundaries. Pause/resume and low frame rates preserve this relationship.
5. Waves remain smooth and phase-continuous across internal states; no teleport, artificial sudden frequency switch, or regular countdown cadence reveals BITE.
6. At the smallest supported screen, band exposure, disappearance, and lateral travel are visible against the actual waterline at the normal fixed observation camera. Test clear and rain conditions; do not solve visibility with a bite-triggered zoom.
7. No UI/audio/haptic cue exposes the hidden hook opportunity. Float-adjacent ripples must follow physical movement and also occur where appropriate in ordinary water motion.
8. Help does not promise that a lift, full submersion, three taps, or a fixed wait guarantees a hook. No species-specific natural-history claims are added without appropriate evidence.

## Repository observations at research time

The read-only inspection of `game/scripts/fishing_session.gd` found a mandatory WAITING → NIBBLE → BITE sequence, hooking by membership in BITE, and `_float_style = hash(species_id) % 3`. The renderer already reads continuous float fields and suppresses separate pre-hook cues, which is a useful interface to preserve. `game/scripts/trial_fishery.gd` still contained “浮漂下沉后提竿”; replace that instruction if alternative valid signals are implemented. These are observations from the working tree during research, not a claim about the final release implementation.
