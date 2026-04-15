# Core Math Test Path

This guide lives under **`.agent/guides/`** (moved from the retired `ai/docs/` folder).

## Purpose

The iOS test target is discoverable from Xcode, but in this assistant environment it often cannot execute because of simulator and host sandbox constraints.

To make the critical navigation math runnable by the assistant, the repo now contains a sidecar Swift package with a pure, non-simulator test path.

## Location

- Package manifest: `Package.swift`
- Package sources: `NavigationCorePackage/Sources/ExtasyNavigationCore`
- Package tests: `NavigationCorePackage/Tests/ExtasyNavigationCoreTests`

## What Is Included

The package currently mirrors the pure math/navigation code that is most important to verify:

- `MathUtilities`
- `VMGCalculator`
- `WaypointProcessor`
- supporting types such as `Layline`

The first mirrored regression suite covers:

- angle wrap behavior around `0/360`
- signed angle behavior around `-180/180`
- date-line bearing cases
- VMG spline regression checks
- layline/intersection geometry checks
- heading wrap stability in tack-state selection

## How To Run

Use:

```bash
swift test --disable-sandbox
```

Run it from the repository root.

`--disable-sandbox` is currently required in this environment because plain `swift test` fails during manifest evaluation with:

- `sandbox_apply: Operation not permitted`

## Why This Exists

This package is intentionally isolated from the app target so we can validate math without:

- iOS simulator boot
- hosted app test execution
- Xcode test harness instability in the assistant sandbox

That makes it the preferred path for fast regression checks on navigation math.

## Important Limitation

This is currently a mirrored pure core, not yet the app's direct source of truth.

That means:

- it is safe for the app because it does not rewire app code
- but future math changes should usually be updated in both places until the code is unified

## Recommended Next Step

Gradually converge the app and package so the tested core becomes the same implementation the app uses. The safest order is:

1. keep adding regression tests here
2. move more pure helpers into the package/core layer
3. switch app modules to depend on the shared core only after coverage is strong
