# CareApp — Design System

The implemented design system for CareApp. Update this file when tokens or patterns change; it is the source of truth for anyone building new screens.

---

## Color tokens

Defined as `static const` on `AppTheme` in `mobile/lib/core/theme/app_theme.dart`.

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#4338CA` | Buttons, icons, hero backgrounds, active states |
| `onPrimary` | `#FFFFFF` | Text/icons on primary surfaces |
| `primaryContainer` | `#E0E7FF` | Light tinted backgrounds (chips, icon wells, tags) |
| `surface` | `#F8F7FF` | Scaffold and screen background |
| `onSurface` | `#1C1B2E` | Body and heading text |
| `onSurfaceVariant` | `#4C4A6B` | Secondary text, placeholders, muted labels |
| `outline` | `#7B7B9A` | Input borders (unfocused) |
| `outlineVariant` | `#CBCAE4` | Card borders, dividers |
| `error` | `#B3261E` | Error text and icons |
| `errorContainer` | `#F9DEDC` | Inline error banners |
| `onErrorContainer` | `#410E0B` | Text inside error banners |

### Semantic status colors (not in AppTheme — used inline)

| Purpose | Icon color | Icon background |
|---|---|---|
| Medication / due soon | `#E07A0A` amber | `#FFF3E0` |
| Appointments / informational | `primary` indigo | `#E0E7FF` |
| Family / done | `#2E7D52` green | `#E8F5E9` |
| Error / overdue | `error` | `errorContainer` |

---

## Typography

Font family: **Inter** via `google_fonts`. Applied through `GoogleFonts.interTextTheme()` in the theme.

| Style | Size | Weight | Usage |
|---|---|---|---|
| `headlineMedium` | 28 | 700 | Auth screen app title |
| `headlineSmall` | 24 | 600 | Home screen greeting |
| `titleLarge` | 20 | 600 | AppBar title |
| `titleMedium` | 16 | 600 | Card section headings, form section labels |
| `titleSmall` | 14 | 600 | Card titles |
| `bodyLarge` | 16 | 400 | Primary body text, field labels |
| `bodyMedium` | 14 | 400 | Secondary body, list content |
| `bodySmall` | 12 | 400 | Empty state captions, timestamps, helper text |
| `labelLarge` | 16 | 600 | Button labels |
| `labelSmall` | 11 | 500 | Tags, badges |

Rules: body text minimum 16px. No text below 11px. Headings use `letterSpacing: -0.5`. Body uses default tracking.

---

## Spacing

8px base grid throughout.

Common values: 4 · 6 · 8 · 12 · 14 · 16 · 20 · 24 · 28 · 32 · 36 · 40 · 48 · 64.

Padding conventions:
- Screen horizontal padding: 20–24px
- Card internal padding: 16px
- Form field vertical padding: 18px (via `contentPadding` in theme)
- Between form fields: 16px
- Hero section bottom padding: 28–40px

---

## Layout patterns

### Auth screens (login / register)

Two-zone immersive layout. No AppBar.

```
Scaffold(backgroundColor: primary)
  SafeArea
    Column
      [Hero zone — primary background, ~230–270px natural height]
        Stack
          Decorative circle 220px  Color(0x0CFFFFFF)   top-right
          Decorative circle 160px  Color(0x08FFFFFF)   bottom-left
          Padding 24/36–48/32–40
            Center
              Stack  ← brand mark
                Circle 96px  Color(0x1AFFFFFF)   halo
                RoundedRect 72px r20  Color(0x33FFFFFF)  icon container
                  Icon health_and_safety_rounded white 36px
              SizedBox 16–20
              Text appTitle  headlineMedium white
              SizedBox 6
              Text authTagline  bodyLarge white 80%
      [Content zone — neutral card, fills remaining space]
        Expanded
          Container
            decoration: surface color, borderRadius vertical top 28px
            SingleChildScrollView padding 24/32
              Form fields
              CTA button
              Secondary text link
```

Key detail: the primary color fills from the status bar to the content card's rounded edge. The card's `28px` top radius creates a deliberate transition line — the only horizon in the design.

### Home screen

Same two-zone pattern, but with an AppBar instead of a brand header.

```
Scaffold(backgroundColor: primary)
  AppBar
    backgroundColor: transparent
    scrolledUnderElevation: 0
    surfaceTintColor: transparent
    foregroundColor: white
    systemOverlayStyle: SystemUiOverlayStyle.light
    title: Row [mini icon container 32px + app name]
    actions: [logout icon]
  body: Column
    [Greeting zone — primary background]
      Padding fromLTRB(20, 8, 20, 28)
        Text homeWelcome  headlineSmall white w700
        Text homeSubtitle  bodyLarge white 80%
    [Content zone]
      Expanded → Container surface / radius vertical top 28px
        SingleChildScrollView
          section cards
          footer text
```

---

## Components

### Cards (section cards)

```
Card  ← theme: white, no elevation, outlineVariant border, r16
  Padding 16
    Row crossAxisAlignment: start
      Container 44×44 r12  colored icon well
        Icon 22px
      SizedBox 14
      Expanded
        Column crossAxisAlignment: start
          Text title  titleSmall
          SizedBox 4
          Text emptyMessage  bodySmall
      Icon chevron_right  outlineVariant 20px
```

### Brand mark (auth hero)

```
Stack alignment: center
  Container 96×96  shape: circle  Color(0x1AFFFFFF)  ← halo
  Container 72×72  borderRadius: 20  Color(0x33FFFFFF)  ← icon bg
    Icon health_and_safety_rounded  white 36px
```

### Form fields

Outlined style via theme `InputDecorationTheme`:
- Fill: white
- Border radius: 12px
- Focused border: `primary` 2px
- All fields have a `prefixIcon` (email, lock, person, phone)

### Buttons

- **Primary action**: `FilledButton` — full width, 52px height, `primary` background, 12px radius
- **Secondary / navigation**: `TextButton` — `primary` foreground, 48px min height

### Error banners

Inline — not toast, not modal. Animated height via `AnimatedSize`:

```
Container
  color: errorContainer
  borderRadius: 10
  padding: 14/12
  Row
    Icon error_outline_rounded  error 18px
    Text error message  bodySmall onErrorContainer
```

---

## Motion

Single authored moment per screen: `AnimatedSize(duration: 180ms, curve: Curves.easeOut)` on error banners — they grow into view, never pop. Everything else is instant. No entrance animations on form fields or cards.

---

## What to carry forward on new screens

1. Use the two-zone layout (primary hero + neutral content card) for any screen with a strong identity moment at the top.
2. Reference `AppTheme.*` constants — never hardcode a hex that exists as a token.
3. Semantic status colors (amber / indigo / green) are the only non-token colors allowed in screen code.
4. New icon wells: follow the 44×44 / 12px-radius / colored-background pattern.
5. New section headers: use `titleSmall` weight. Empty states: `bodySmall` muted.
6. Touch targets ≥ 48px. WCAG AA on all text surfaces.
