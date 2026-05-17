# HealthKit Plan for Activity Tracking

## Scope

This document is intentionally separate from the main activity tracker plan.

HealthKit will be handled later, after the non-HealthKit activity improvements are complete.

## What HealthKit would require

- Add the `HealthKit` capability to the app target in Xcode.
- Add `NSHealthShareUsageDescription` to `Info.plist` if reading health data.
- Add `NSHealthUpdateUsageDescription` to `Info.plist` if writing health data.
- Call `HKHealthStore.isHealthDataAvailable()` before requesting access.
- Request authorization with the exact types needed, not a blanket permission.
- Use `HKWorkoutType.workoutType()` if the goal is importing workout sessions.

## What this plan does not cover

- No implementation details yet.
- No schema changes yet.
- No UI changes yet.
- No import button yet.
- No sync logic yet.

## Why it is deferred

- The current app already has manual activity logging.
- The next useful wins are search, edit, discard confirmation, and date grouping.
- HealthKit adds platform complexity and should be done last.

## Future decision points

- Read-only import or read/write sync
- One-time import or continuous sync
- Workout-only import or broader health data import
- Manual override behavior when imported data conflicts with user-entered data

## Status

- Deferred
- Not scheduled before the activity improvements listed in `plan-activity-tracker.md`
