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

## Two different “modes” (source of app confusion)

1. **Boat mode (TWA vs polar threshold):** “Am I sailing in the **upwind** or **downwind** band of the polar **right now**?” — drives **VMG bars**, **optimal TWA for trimming**, **generic wind laylines from the boat**.

2. **Mark geometry (bearing to mark vs TWD):** “Is **this mark** in the **upwind or downwind** sector of the wind field?” — drives **mark‑centric layline corridor** and is **stable if heading wobbles** (good for chart geometry).

Those two **can disagree near the threshold** (e.g. sailing **upwind TWA** while AoM is barely past the polar’s upwind/downwind boundary). A **tactician** still sails the **actual leg** (upwind beat vs downwind); the **mark laylines** for that leg should use the **same optimal tack angle family** as the leg you are sailing, or the chart will disagree with “what’s fast.”

## Fastest path to the mark (what you want on the water)

- **Mark to windward (you are beating):** fastest course to that mark is driven by **upwind polar optimum** (close‑hauled VMG), not downwind angles — laylines through the mark should use **optimal upwind TWA** for that TWS.
- **Mark to leeward (you are running):** use **downwind** polar optimum for laylines / gybing geometry.
- **“No matter what the label says”:** if one classifier says “downwind” but you are clearly in **upwind TWA band**, you still sail and plan with **upwind optimum** for speed to a windward mark.

**Extasy behaviour:** diamond laylines use **polar sailing mode from live TWA** (`VMGData.sailingState`) when it is `Upwind` or `Downwind`; otherwise they fall back to mark‑vs‑TWD (`waypointApproachState`). The **mark** badge in debug can still show mark‑centric state for context.

**Future product (see `.agent/ROADMAP.md`):** **Downwind path advisor** — compare time‑to‑mark for **rhumb / straight** vs **one or more gybes** at polar‑optimal TWA using **VMC** and polar boat speed; start simple (stay vs one gybe) before full routing.

## VMG vs VMC (one line each)

- **VMG:** “How well am I working the **wind**?” (no mark required.)
- **VMC:** “How well am I going **toward this mark**?” (mark required; best tack can flip with geometry.)

## Favored tack (racing shorthand)

**Favored tack** usually means the tack whose **heading points more toward the next significant target** (mark, finish, better pressure), **not** merely which VMC number is larger at one instant — shifts, traffic, and **future** laylines matter. For **instrument displays**, “higher VMC on this tack” is a **simplified** favored‑tack hint.

## Sources (public, stable enough to cite)

- Windward mark laylines and early‑layline trap: [SailZing — Windward mark approach](https://sailzing.com/windward-mark-approach-six-traps-to-avoid/)
- Race course / windward leg basics: [SailZing — Windward leg for beginners](https://sailzing.com/sailing-the-race-course-windward-leg-for-beginners/)
- Course management / big‑picture tactics: [America’s Cup — race tactics & course management](https://www.americascup.com/news/3234_RACE-TACTICS-COURSE-MANAGEMENT-WHAT-TO-LOOK-FOR)
- Leeward / gate layline ideas (traffic funnel): [Sailing World — gate roundings](https://www.sailingworld.com/how-to/guide-to-tactical-gate-roundings/)

## When editing Extasy Complete Navigation

- **Layline diamond** uses **TWA / polar mode** when known, else mark vs TWD — so boat and mark rays match **optimal up or down angles you are actually sailing**; do not revert to mark‑only if that re‑introduces the AoM threshold bug.
- **Do not drive laylines from COG alone** — heading wobble should not swing geometry; TWD + polar state + positions are the right inputs.
- **Current leg “Upwind / Downwind” labels** for the **boat** should follow **TWA / polar mode**, not only mark AoM, or the UI contradicts how the crew is sailing.
- **VMC row** compares tacks **toward the mark**; do not relabel it as VMG.
- Respect **Kalman‑smoothed TWD** and **vector wind** handling already in the codebase when reasoning about rotation of laylines over time.

## Anti‑patterns

- Mixing **optimal downwind TWA** into a **windward** layline because a numeric AoM threshold flickered.
- Drawing **only** boat‑origin rays and calling them “laylines to the mark” without rays **through the mark** — incomplete geometry.
- Equating **“fast VMG”** with **“good VMC”** — you can sail the wind well and still sail away from the mark.
