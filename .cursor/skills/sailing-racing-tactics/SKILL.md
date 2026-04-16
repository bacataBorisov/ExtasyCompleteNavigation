---
name: sailing-racing-tactics
description: >-
  Racing sailboat tactics, laylines, VMG/VMC/polars, and how they map to instrument
  apps. Use when discussing Extasy Navigation, laylines, windward/leeward legs,
  polars, tacks/gybes, VMC vs VMG, or sailing UX and geometry in code.
---

# Sailing racing tactics (tactician lens)

Use this when reasoning about **navigation math**, **UI labels**, or **polar-driven features** so answers match how good race teams and AC-style software think — not ad‑hoc guesses.

## Core quantities (instrument vocabulary)

| Term | Meaning |
|------|---------|
| **TWD** | Compass direction **from which true wind blows** (meteorological convention). |
| **TWA** | Angle between boat heading and true wind; **< 180°** one side, **> 180°** other (wind on port vs starboard). |
| **Bearing to mark** | True compass bearing **boat → mark**. |
| **AoM / angle on mark** | Bearing of mark **relative to wind** (often \(\lvert \text{bearingToMark} - \text{TWD} \rvert\) normalized to 0–180°). Tells whether the mark lies in the **upwind** or **downwind** sector of the course **independent of boat heading**. |
| **VMG** | Speed made **toward or away from the wind** along the wind axis (polar “upwind” vs “downwind” mode). |
| **VMC** | Speed made **toward a specific point** (mark) — dot product of velocity with unit vector to mark. |
| **Polar / VPP** | Model of target boat speed and often **optimal upwind and downwind TWA** vs TWS — not a single “best angle” for all cases. |

## Laylines — what they are

**Laylines (to a mark)** are the **two straight lines through the mark** (in the horizontal plane) that a boat sailing **at the relevant optimal tack angle** to the wind would follow **on starboard tack vs port tack** to **just fetch** the mark on that tack. They form the edges of the **valid layline cone / corridor** approaching that mark.

- **Windward beat:** laylines use **upwind (close‑hauled) optimal TWA** from the polar for that TWS.
- **Downwind run / gybe angles:** laylines use **downwind optimal TWA** (often much larger than upwind).

Laylines **rotate with TWD shifts** and **open or close** with wind speed (optimal TWA and threshold between “upwind” and “downwind” polar modes change with TWS).

**Tactical note (fleet racing):** hitting the layline **very early** is often wrong — you lose shift options and get “layline parade” traffic. Software still draws full geometry; the human tactician chooses **when** to commit.

## How chartplotters stabilise laylines (what other makers do)

Instruments agree laylines **must** follow wind and polar angles, but **raw** updates can make the chart unreadable. Common patterns:

| Source | Mechanism | Notes |
|--------|-----------|--------|
| **Garmin GPSMAP** (sailing) | **[Layline Filter](https://www8.garmin.com/manuals/webhelp/GUID-3E67C80C-0812-4EEC-BC60-699751B9CF6F/EN-US/GUID-452E9A3D-1C2B-42C0-87EC-D06BE8927AD8.html)** — time interval; higher = smoother, filters **heading / TWA** jitter. | Explicit user control (“smoother vs more sensitive”). |
| **Garmin** | **Sailing Ang.** = **Actual** (sensor) vs **Manual** (fixed windward/leeward angles) vs **Polar table**. | Manual = ignore short-term wind noise; polar = TWS-dependent angles like Extasy’s polars. |
| **B&G / Zeus** (community docs) | TWD from mast wind + motion; **[Use COG as heading](https://copelands.blog/2019/08/29/configuring-true-wind-direction-twd-and-true-wind-speed-tws-on-a-bg-zeus-3-chart-plotter/)** (and SOG as speed) option to **stabilise TWD** in current — tradeoff: TWA vs water becomes less “pure”. | Same physics problem: **ground-referenced** wind can be steadier when **HDG** lags or wanders in tacks. |
| **Racing / nav suites** (e.g. Expedition, SailTimer class) | Often **user wind** or **averaged TWD**, sometimes **mark type** (windward vs leeward) to pick layline family. | Less automatic twitching; crew accepts responsibility for wrong manual wind. |

**Why lines “dance” without filtering**

1. **TWD from HDG + TWA** (typical NMEA MWV “true”): any **heading** step or lag rotates derived TWD even if the **true** wind field is steady.  
2. **Polar up/down mode from live TWA**: crossing the polar’s **upwind / downwind** threshold swaps **optimal up TWA** vs **optimal down TWA** in the layline math — a **large** geometric jump unrelated to a small mark move.  
3. **True wind shifts** (5° shift ≈ 5° line rotation) — correct behaviour; filtering should **not** remove real persistent shifts, only **high-frequency** noise.

**Extasy (implementation intent)**

- **Instruments / VMC / labels**: keep **live** `WindData.trueWindDirection` (already Kalman-smoothed in `WindProcessor`).  
- **Diamond laylines on the map** (`WaypointProcessor`): **(1)** circular low-pass **TWD** used only for layline math (slower blend than before — same *class* as Garmin **Layline Filter**: chart ignores short spikes from HDG/TWA coupling in a tack); **(2)** low-pass **polar optimal up/down TWA** used only for ray angles (damps TWS table jitter); **(3)** **mark vs smoothed TWD** for upwind vs downwind **family**. Lines are **filtered**, not **locked** — a real persistent shift or new TWS band still moves them; that matches well-tested plotter behaviour.

## Two different “modes” (source of app confusion)

1. **Boat mode (TWA vs polar threshold):** “Am I sailing in the **upwind** or **downwind** band of the polar **right now**?” — drives **VMG bars**, **optimal TWA for trimming**, **generic wind laylines from the boat**.

2. **Mark geometry (bearing to mark vs TWD):** “Is **this mark** in the **upwind or downwind** sector of the wind field?” — drives **mark‑centric layline corridor** and is **stable if heading wobbles** (good for chart geometry).

Those two **can disagree near the threshold** (e.g. sailing **upwind TWA** while AoM is barely past the polar’s upwind/downwind boundary). A **tactician** still sails the **actual leg** (upwind beat vs downwind); the **mark laylines** for that leg should use the **same optimal tack angle family** as the leg you are sailing, or the chart will disagree with “what’s fast.”

**Extasy tradeoff:** diamond laylines prefer **mark vs smoothed TWD** for that family choice so the **map** does not swap up/down tack angles when **polar boat mode** flickers; you may rarely see chart laylines in the “other” polar band — prefer **crew / polar readouts** for “what mode we are sailing.”

## Fastest path to the mark (what you want on the water)

- **Mark to windward (you are beating):** fastest course to that mark is driven by **upwind polar optimum** (close‑hauled VMG), not downwind angles — laylines through the mark should use **optimal upwind TWA** for that TWS.
- **Mark to leeward (you are running):** use **downwind** polar optimum for laylines / gybing geometry.
- **“No matter what the label says”:** if one classifier says “downwind” but you are clearly in **upwind TWA band**, you still sail and plan with **upwind optimum** for speed to a windward mark.

**Extasy behaviour:** **Map diamond laylines** use **layline‑only smoothed TWD** + **smoothed polar tack angles** for the rays, plus **bearing‑to‑mark vs smoothed TWD** for up/down **family**. **`waypointApproachState`** and VMC still use **live** TWD vs mark for tactics. Polar **`sailingState`** remains authoritative for **VMG bars** and trim hints, not for swapping layline tack‑angle family on every threshold cross.

**Future product (see `.agent/ROADMAP.md`):** **Downwind path advisor** — compare time‑to‑mark for **rhumb / straight** vs **one or more gybes** at polar‑optimal TWA using **VMC** and polar boat speed; start simple (stay vs one gybe) before full routing. Optional **Settings** later: Garmin‑style **layline filter interval** or **manual layline wind** if users want full control.

## VMG vs VMC (one line each)

- **VMG:** “How well am I working the **wind**?” (no mark required.)
- **VMC:** “How well am I going **toward this mark**?” (mark required; best tack can flip with geometry.)

## Favored tack (racing shorthand)

**Favored tack** usually means the tack whose **heading points more toward the next significant target** (mark, finish, better pressure), **not** merely which VMC number is larger at one instant — shifts, traffic, and **future** laylines matter. For **instrument displays**, “higher VMC on this tack” is a **simplified** favored‑tack hint.

## Sources (public, stable enough to cite)

- Garmin GPSMAP — [Laylines settings (Layline Filter, Sailing Ang., manual angles)](https://www8.garmin.com/manuals/webhelp/GUID-3E67C80C-0812-4EEC-BC60-699751B9CF6F/EN-US/GUID-452E9A3D-1C2B-42C0-87EC-D06BE8927AD8.html)
- B&G Zeus / TWD configuration (COG vs heading tradeoff): [The Copelands — TWD on B&G Zeus 3](https://copelands.blog/2019/08/29/configuring-true-wind-direction-twd-and-true-wind-speed-tws-on-a-bg-zeus-3-chart-plotter/)
- Windward mark laylines and early‑layline trap: [SailZing — Windward mark approach](https://sailzing.com/windward-mark-approach-six-traps-to-avoid/)
- Race course / windward leg basics: [SailZing — Windward leg for beginners](https://sailzing.com/sailing-the-race-course-windward-leg-for-beginners/)
- Course management / big‑picture tactics: [America’s Cup — race tactics & course management](https://www.americascup.com/news/3234_RACE-TACTICS-COURSE-MANAGEMENT-WHAT-TO-LOOK-FOR)
- Leeward / gate layline ideas (traffic funnel): [Sailing World — gate roundings](https://www.sailingworld.com/how-to/guide-to-tactical-gate-roundings/)

## When editing Extasy Complete Navigation

- **Layline diamond**: `WaypointProcessor` — **smoothed TWD** (`laylineWindDirectionSmoothed`), **smoothed optimal up/down TWA** for rays only, **mark vs smoothed TWD** for up/down **family**; **reset** all layline smoothers when waypoint cleared. Optional **Settings** later: user‑tunable blend or Garmin‑style **Layline Filter** interval.
- **Do not drive laylines from COG alone** — use TWD (smoothed for chart) + mark position + polar **optimal TWA** for the chosen up/down **family**.
- If you re‑introduce **polar `sailingState` for diamond tack‑angle family**, document the **AoM edge case** vs **chart twitch** tradeoff in this skill and consider a **user toggle** (Actual / Mark only / Polar sync).
- **Current leg “Upwind / Downwind” labels** for the **boat** should follow **TWA / polar mode**, not only mark AoM, or the UI contradicts how the crew is sailing.
- **VMC row** compares tacks **toward the mark**; do not relabel it as VMG.
- Respect **Kalman vector TWD** in `WindProcessor` for live data; **`WaypointProcessor`** applies an additional **slower** circular blend **only** for diamond laylines — two stages are intentional (instruments responsive, chart calm).

## Anti‑patterns

- Mixing **optimal downwind TWA** into a **windward** layline because a numeric AoM threshold flickered.
- Drawing **only** boat‑origin rays and calling them “laylines to the mark” without rays **through the mark** — incomplete geometry.
- Equating **“fast VMG”** with **“good VMC”** — you can sail the wind well and still sail away from the mark.
