# NutriWeek Turkish Localization Audit

## Scope

This document audits the Turkish (`tr`) entries in [Localizable.xcstrings](/Users/jans/Downloads/NutriWeek-Planner/iOS/NutriWeek/NutriWeek/Localizable.xcstrings) and describes what should be corrected before the localization is considered production-quality.

Focus areas:

- Turkish character usage and orthography
- Meaning accuracy
- Naturalness of phrasing for iOS UI copy
- Consistency of style across feature areas

This is a quality audit, not an implementation plan for new localization plumbing.

## Current State

The catalog already has full `en` and `tr` coverage for the reviewed keys. Coverage is not the problem.

The problem is quality:

- Most Turkish strings are written in ASCII transliteration rather than proper Turkish characters.
- Some entries are semantically weak or unnatural.
- A few translations are plainly wrong or awkward enough to read as machine-generated.

In short: the app is localized, but not yet well localized.

## Main Problems

### 1. Turkish characters are mostly missing

Only a tiny subset of the Turkish strings use proper Turkish characters like `ç`, `ğ`, `ı`, `İ`, `ö`, `ş`, `ü`.

In the current catalog, only 3 translated values include Turkish-specific letters. The rest are mostly ASCII transliterations or symbol-only strings.

Examples:

- `Henuz` should be `Henüz`
- `Gunaydin` should be `Günaydın`
- `Yag` should be `Yağ`
- `Gogus` should be `Göğüs`
- `Koser` should be `Koşer`

This is the biggest quality issue because it makes the UI look unpolished and inconsistent.

### 2. Some meanings are inaccurate

Several entries are not just missing diacritics; they are semantically wrong.

Examples:

- `diet.nut_free => Kuruyemisli`
  - Problem: this means "with nuts", not "nut-free".
  - Better: `Kuruyemişsiz` or `Kuruyemiş içermez`
- `activity.sedentary => Sedanter`
  - Problem: technically understandable, but not the most natural Turkish UI label.
  - Better: `Hareketsiz`

### 3. Some translations are unnatural or awkward

These are understandable, but they read like direct translation instead of native UI copy.

Examples:

- `meal_plan.fun_fact.hands`
  - Current: `Bir rakunun ellerinde seninki gibi 5 parmak vardir`
  - Better: `Bir rakunun ellerinde de seninki gibi 5 parmak vardır.`
- `meal_plan.fun_fact.locks`
  - Current: `Rakunar kilit acabilir!`
  - Problem: typo and unnatural wording.
  - Better: `Rakunlar kilit açabilir!`
- `goal.bulk.subtitle`
  - Current: `Kalori fazlasi · Guclen · Buyu`
  - Better: `Kalori fazlası · Güçlen · Büyü`
- `goal.cut.subtitle`
  - Current: `Kalori acigi · Daha fit gorun · Hafif hisset`
  - Better: `Kalori açığı · Daha fit görün · Hafif hisset`

### 4. Some casing and microcopy rules are inconsistent

Examples:

- `common.date => TARIH`
  - This is all caps and reads like a label dump.
  - Better: `Tarih`
- `meal_plan.greeting.morning => Gunaydin!`
  - Better: `Günaydın!`
- `meal_type.lunch => Ogle Yemegi`
  - Better: `Öğle Yemeği`

### 5. Some strings are intentionally technical and do not need translation

Not every ASCII-looking value is a localization problem.

These are fine as-is when they are used as format templates, protocol tokens, or symbolic labels:

- `%1$lld/%2$lld`
- `%1$lld%% · %2$lldg`
- `🥩 %1$@g · 🍚 %2$@g · 🥑 %3$@g`
- `+`
- `✓`
- `✕`
- brand names such as `NutriWeek` and `Rocky`

For UI text, sentence case is usually cleaner unless the design system explicitly wants uppercase labels.

## Priority Fix List

### P0: Fix wrong meanings

These should be corrected first because they change the actual message:

- `diet.nut_free`
- `activity.sedentary`
- `meal_plan.fun_fact.locks`

### P1: Add proper Turkish characters

These should be corrected next because they affect most of the catalog:

- `Henuz` -> `Henüz`
- `Gunaydin` -> `Günaydın`
- `Yag` -> `Yağ`
- `Gogus` -> `Göğüs`
- `Kalca` -> `Kalça`
- `Sikilasmaya` -> `Sıkılaşmaya`
- `Olustur` -> `Oluştur`
- `Kayit` -> `Kayıt`
- `Duzeyi` -> `Düzeyi`

### P2: Improve naturalness

These are valid but can be made more native:

- greeting strings
- Rocky voice lines
- goal subtitles
- onboarding guidance lines
- empty states and error messages

## Recommended Translation Standards

### Orthography

- Use proper Turkish characters everywhere possible.
- Avoid ASCII-only transliteration unless the string is a protocol token, code value, or intentionally technical.
- Keep brand names and product names as-is if they are already established, for example `NutriWeek` and `Rocky`.

### Meaning

- Preserve the exact meaning of the source string.
- Do not translate `nut-free` as `with nuts`.
- Do not let technical terms override user-facing clarity.

### Tone

- Keep the tone friendly and short.
- For UI labels, prefer plain Turkish over literal English structure.
- For Rocky-style copy, keep the playful tone, but still use correct Turkish.

### Formatting

- Do not alter placeholders like `%d`, `%lld`, `%@`, or format order tokens.
- Do not change emoji placement unless there is a strong reason.
- Keep key contract strings intact when the string is used as a format template or protocol value.

## Concrete Suggested Rewrites

Below are the most important strings that should be updated first.

| Key | Current `tr` value | Suggested `tr` value |
|---|---|---|
| `diet.kosher` | `Koser` | `Koşer` |
| `diet.nut_free` | `Kuruyemisli` | `Kuruyemişsiz` |
| `activity.sedentary` | `Sedanter` | `Hareketsiz` |
| `meal_plan.fun_fact.hands` | `Bir rakunun ellerinde seninki gibi 5 parmak vardir` | `Bir rakunun ellerinde de seninki gibi 5 parmak vardır.` |
| `meal_plan.fun_fact.locks` | `Rakunar kilit acabilir!` | `Rakunlar kilit açabilir!` |
| `common.date` | `TARIH` | `Tarih` |
| `meal_type.lunch` | `Ogle Yemegi` | `Öğle Yemeği` |
| `meal_type.breakfast` | `Kahvalti` | `Kahvaltı` |
| `meal_type.dinner` | `Aksam Yemegi` | `Akşam Yemeği` |
| `meal_type.snack` | `Ara Ogun` | `Ara Öğün` |
| `goal.bulk.subtitle` | `Kalori fazlasi · Guclen · Buyu` | `Kalori fazlası · Güçlen · Büyü` |
| `goal.cut.subtitle` | `Kalori acigi · Daha fit gorun · Hafif hisset` | `Kalori açığı · Daha fit görün · Hafif hisset` |

## Verification Checklist

After updating the catalog:

1. Re-scan the `tr` values for ASCII-only transliteration.
2. Check that every user-facing string reads naturally to a native Turkish speaker.
3. Verify that format placeholders still match the source keys.
4. Confirm no meaning changes were introduced for dietary terms.
5. Run the app in Turkish locale and spot-check:
   - onboarding
   - meal plan home
   - log view
   - profile view

## Recommendation

The current localization should be treated as a functional baseline, not a finished Turkish release.

Best next step:

- First fix the P0 meaning errors.
- Then replace transliterated strings with correct Turkish characters.
- Finally do a pass for natural, native-sounding UI copy.
