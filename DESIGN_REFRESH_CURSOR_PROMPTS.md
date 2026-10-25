# Main tabs refresh — Cursor prompts

Restyle the Workouts, Journey and Nutrition tabs to match the onboarding flow.
Agreed mockups: https://claude.ai/artifact/EVKE4Lp2UAJVHN4HqjRx22 (private to Tom; Cursor can't open it).

## How to run these

1. Run the prompts **in order**, each in a **new Cursor Agent chat**. Every prompt repeats the rules it needs, so it stands on its own.
2. After each prompt: build (⌘B), run in the simulator, check light **and** dark mode, then commit before the next prompt.
3. Prompt 0 must land first; the others depend on the components it creates.

| # | Prompt | Depends on |
|---|--------|-----------|
| 0 | Shared design system (`AppTheme.swift`) | — |
| 1 | Workouts tab — resting state | 0 |
| 2 | Workouts tab — workout in progress | 0, 1 |
| 3 | Journey tab | 0 |
| 4 | Nutrition tab | 0 |
| 5 | Polish and QA pass | 0–4 |

---

## Prompt 0 — Shared design system

````text
You are working in the Progress iOS app (SwiftUI, SwiftData, iOS 17+). Read these files first:
- Progress/Features/Onboarding/Views/OnboardingTheme.swift   (the visual language we are adopting)
- Progress/Resources/DesignTokens/Colours.swift               (Color.brand, AdaptiveGradientBackground, whiteCardStyle)
- Progress/Resources/DesignTokens/Typography.swift

GOAL
The onboarding flow has a polished look (OnboardingPalette, OnboardingBackground, ink pill buttons,
white floating cards, emoji tiles). The three main tabs do not use it. Create ONE new file that exposes
that look app-wide so later prompts can restyle the tabs. This prompt adds code only; it must not
change how any existing screen looks.

CREATE: Progress/Resources/DesignTokens/AppTheme.swift

1. Aliases (do NOT move or rename anything in OnboardingTheme.swift; onboarding must keep compiling unchanged):
   typealias AppPalette = OnboardingPalette
   typealias AppBackground = OnboardingBackground

2. Extra palette values, as `extension OnboardingPalette` (so they are reachable as AppPalette.x):
   - protein  = Color(hex: "FF6B6B")
   - carbs    = Color(hex: "F39C12")
   - fat      = Color(hex: "45B7D1")
   - live     = Color(hex: "34C759")   // "in progress" green
   - liveText = dynamic: light #1C6B33, dark #7EE29A
   - static func tint(_ hue: Color) -> Color { hue.opacity(0.14) }   // soft tile/chip background, works in dark mode

3. Typography — `extension Font`:
   - appScreenTitle  = .system(size: 34, weight: .heavy, design: .rounded)   // use with .tracking(-0.5)
   - appSectionTitle = .system(size: 22, weight: .heavy, design: .rounded)
   - appCardTitle    = .system(size: 16, weight: .heavy)
   - appBigNumber    = .system(size: 32, weight: .heavy, design: .rounded)  // use .monospacedDigit()
   - appEyebrow      = .system(size: 11, weight: .heavy)                     // use .tracking(1), uppercase
   - appSubtitle     = .system(size: 13, weight: .semibold)                  // colour AppPalette.muted

4. Card modifiers — `extension View`:
   - appCard(cornerRadius: CGFloat = 22, padding: CGFloat = 14)
       .padding(padding)
       background: RoundedRectangle(cornerRadius, style: .continuous).fill(AppPalette.surface)
       overlay:    same shape .strokeBorder(AppPalette.line, lineWidth: 1)
       shadow:     Color.black.opacity(0.08), radius 14, x 0, y 8
   - appGroupRow(cornerRadius: CGFloat = 20)
       .padding(.horizontal, 14).padding(.vertical, 12)
       background: RoundedRectangle(cornerRadius, style: .continuous).fill(AppPalette.optionFill)
   - appFloatingChip()   // small white chip that floats over content
       .padding(.horizontal, 12).padding(.vertical, 8)
       background: RoundedRectangle(14, .continuous).fill(AppPalette.surface)
       shadow: Color.black.opacity(0.16), radius 10, x 0, y 5

5. Components (structs, each with a #Preview showing light and dark):
   - EmojiTile(emoji: String, size: CGFloat = 46, background: Color = AppPalette.accentSoft)
       Text(emoji).font(.system(size: size * 0.52)); frame size×size;
       RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(background); accessibilityHidden(true)
   - CircleIconButton(systemName: String, style: Style = .plain, size: CGFloat = 40, accessibilityLabel: String, action: () -> Void)
       enum Style { case plain, ink }
       .plain: Circle fill AppPalette.surface + strokeBorder AppPalette.line 1pt; icon AppPalette.ink
       .ink:   Circle fill AppPalette.ink; icon AppPalette.onInk; shadow black 0.22, radius 8, y 6
       icon: .system(size: size * 0.42, weight: .bold)
   - ChevronToggleButton(isExpanded: Bool, size: CGFloat = 30, accessibilityLabel: String, action: () -> Void)
       Circle fill AppPalette.optionFill; Image("chevron.down") .system(size: size * 0.45, weight: .bold) AppPalette.ink;
       .rotationEffect(.degrees(isExpanded ? 180 : 0)); .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
   - AppProgressBar(progress: Double, height: CGFloat = 6)
       Capsule track AppPalette.line; Capsule fill AppPalette.accentGradient, width = clamp(progress, 0...1) × width;
       animate with .spring(response: 0.45, dampingFraction: 0.85)
   - AppPillButtonStyle: ButtonStyle
       enum Kind { case ink, outline, inverse }   enum Size { case large, compact }
       .large   → height 50, maxWidth .infinity, font .system(size: 16, weight: .bold)
       .compact → height 38, horizontal padding 16, font .system(size: 14, weight: .bold)
       .ink     → Capsule fill AppPalette.ink, text AppPalette.onInk, shadow black 0.25 radius 9 y 6
       .outline → Capsule fill AppPalette.surface + strokeBorder AppPalette.line 1.5, text AppPalette.ink
       .inverse → Capsule fill AppPalette.onInk, text AppPalette.ink (for use on an ink-coloured card)
       pressed: scaleEffect 0.98, spring(response: 0.3, dampingFraction: 0.7)
   - SessionDots(current: Int, total: Int = 5)
       HStack(spacing: 4) of 8pt circles. index <= current → filled Color.brand.
       index > current → stroke 1.5pt Color.brand.opacity(0.45).
       The LAST index is the deload session: stroke Color.orange (filled orange if index <= current).
       Keep the per-dot accessibility labels that PlanSessionDotStrip in TrainingPlanCard.swift uses today
       (move that logic here).

RULES
- Do not edit any existing screen in this prompt. Do not delete AdaptiveGradientBackground or whiteCardStyle
  (other screens still use them).
- Every colour must come from AppPalette / Color.brand so dark mode keeps working.
- Build must succeed with zero new warnings.

DONE WHEN
- AppTheme.swift compiles, previews render in light and dark, onboarding looks identical to before.
````

---

## Prompt 1 — Workouts tab (resting state)

````text
You are working in the Progress iOS app (SwiftUI). Prompt 0 already added
Progress/Resources/DesignTokens/AppTheme.swift (AppPalette, AppBackground, appCard, appGroupRow, EmojiTile,
CircleIconButton, ChevronToggleButton, AppProgressBar, AppPillButtonStyle, SessionDots, Font.app*). Read it first.

Then read:
- Progress/Features/Workouts/Views/WorkoutListView.swift
- Progress/Features/Workouts/Views/Components/WorkoutListHeader.swift
- Progress/Features/Workouts/Views/Components/TrainingPlanCard.swift
- Progress/Features/Workouts/Views/Components/WorkoutRowView.swift
- Progress/Features/Workouts/Views/Components/WorkoutListContent.swift

RULES (apply to every change below)
- Visual and layout changes only. Do NOT change SwiftData models, @Query predicates, navigation destinations,
  swipe actions (share/delete), the sort menu options, the share sheet, alerts or haptics.
- Use only AppTheme components/colours. No Color.blue, Color(.systemGray6), .largeTitle, whiteCardStyle or
  whiteCardStyleWithBorder left in these five files.
- Screen horizontal padding 20pt (was 24). Vertical gap between the plan card and the "Your workouts" section 18pt.
- Keep existing accessibility labels; add the new ones listed.

CHANGES — FROM → TO

1. Background (WorkoutListView)
   FROM: AdaptiveGradientBackground()
   TO:   AppBackground()

2. Page structure (WorkoutListView + WorkoutListContent)
   FROM: header and TrainingPlanCard sit fixed above a List, so only the workout rows scroll.
   TO:   the whole page scrolls as one. Put the TrainingPlanCard (and, after Prompt 2, the active workout card)
         inside the List as the first rows (listRowBackground(.clear), listRowSeparator(.hidden),
         listRowInsets top 0 / leading 20 / bottom 18 / trailing 20). Keep swipe actions on workout rows only.
         The header stays pinned above the List.

3. Header (WorkoutListHeader)
   FROM: Text("Workouts") .largeTitle bold; three bare SF Symbol glyphs (chart, sort, plus) in .title2.
   TO:   HStack(spacing: 10):
         - Text("Workouts").font(.appScreenTitle).tracking(-0.5).foregroundColor(AppPalette.ink)
         - Spacer
         - CircleIconButton("chart.line.uptrend.xyaxis", .plain, 40, label "Progress history") → onHistoryTapped
         - the existing sort Menu, its label replaced by the same 40pt .plain circle with "arrow.up.arrow.down"
           (icon tinted Color.brand when sortOption != .dateCreated, as today), label "Sort workouts"
         - CircleIconButton("plus", .ink, 40, label "New workout") → onAddTapped
         Padding: horizontal 20, top 16, bottom 18.
         NO subtitle line under the title.

4. Plan card container (TrainingPlanCard)
   FROM: .whiteCardStyle(cornerRadius: 16, padding: 20); "YOUR PLAN" .caption semibold; plan.name .title3 semibold;
         plan.splitType.displayName subtitle.
   TO:   .appCard(cornerRadius: 26, padding: 18), VStack(alignment: .leading, spacing: 14).
         Header row HStack:
           - VStack(spacing 2): Text("YOUR PLAN").font(.appEyebrow).tracking(1).foregroundColor(AppPalette.muted)
                                Text(plan.name).font(.system(size: 22, weight: .heavy)).foregroundColor(AppPalette.ink)
           - Spacer
           - ChevronToggleButton(isExpanded:, size: 34, label: isExpanded ? "Collapse plan" : "Expand plan")
         REMOVE the plan.splitType.displayName line.
         Expanded state persists: @AppStorage("workouts.planCard.expanded") default true.
         Toggle with withAnimation(.spring(response: 0.35, dampingFraction: 0.85)).

5. Plan progress (new, expanded state only, under the header)
   AppProgressBar(progress: done / total) then Text("\(done) of \(total) sessions done").font(.appSubtitle).foregroundColor(AppPalette.muted)
   total = number of non-deleted plan workouts × 5
   done  = sum over those workouts of ((planSessionIndex ?? 1) - 1)

6. "Up next" logic (new, put it in a small helper inside TrainingPlanCard.swift)
   FROM: rows sorted alphabetically by name, all identical.
   TO:   upNext = the non-deleted plan workout with the LOWEST planSessionIndex.
         Tie-break 1: the one trained least recently — the latest completedAt among workouts whose
                      sourceWorkoutId == candidate.id (never trained sorts first).
         Tie-break 2: name, alphabetical.
         Row order: upNext first, the rest by name.
         Example: Upper "2 of 5", Lower "1 of 5", Abs "1 of 5" → Lower or Abs is up next (whichever was trained
         longer ago), never Upper.

7. Up-next row (replaces PlanWorkoutRow for the upNext workout)
   Container: VStack(spacing: 12), padding 14, RoundedRectangle(20, .continuous) fill AppPalette.accentSoft,
              strokeBorder Color.brand lineWidth 2.
   Top HStack(spacing 12):
     - EmojiTile(emoji: planEmoji(for: name), size: 46, background: AppPalette.surface)
     - VStack(alignment: .leading, spacing: 4):
         HStack(spacing 8): Text(name).font(.system(size: 17, weight: .heavy))
                            + badge Text("UP NEXT") 11 heavy, white text, Capsule fill Color.brand, padding h8 v3
         HStack(spacing 8): Text("Session \(i) of 5").font(.appSubtitle) + SessionDots(current: i)
   Bottom: Button("Start workout", trailing Image("arrow.right")) .buttonStyle(AppPillButtonStyle(.ink, .large))
           → same action as today (HapticFeedback.workoutButtonTap() then onStartWorkout(workout)).

8. Other plan rows (PlanWorkoutRow)
   FROM: HStack, padding 14, Color(.systemGray6) RoundedRectangle(12); blue "Start" with RoundedRectangle(10).
   TO:   .appGroupRow(cornerRadius: 20), HStack(spacing 12):
         EmojiTile(planEmoji, 46, background: AppPalette.surface) |
         VStack(4): Text(name).font(.appCardTitle); HStack: "Session i of 5" (.appSubtitle, muted) + SessionDots |
         Spacer | Button("Start").buttonStyle(AppPillButtonStyle(.outline, .compact)) → same action as today.
   DELETE the private PlanSessionDotStrip / PlanSessionDot (replaced by SessionDots).

9. planEmoji(for name: String) -> String (helper in TrainingPlanCard.swift, case-insensitive "contains"):
   upper → "💪", lower or leg → "🦵", abs or core → "🔥", push → "🏋️", pull → "🧗", full → "⚡️", default → "🏋️".

10. Collapsed plan card (expanded == false)
    Show only the header row plus a wrapping row of pills (spacing 6), one per plan workout in the same order:
    Text("\(emoji) \(name) \(i)/5") 12 heavy, foreground AppPalette.ink.opacity(0.75), Capsule fill AppPalette.optionFill,
    padding h10 v6. (Prompt 2 adds the "live" variant.)

11. "Your workouts" section (WorkoutListContent)
    FROM: rows only.
    TO:   above the first custom workout row, a header row Text("YOUR WORKOUTS") 13 heavy, tracking 0.4,
          AppPalette.muted, leading padding 4. Hide it when the list is empty.

12. Workout row (WorkoutRowView)
    FROM: 48pt blue circle with "dumbbell.fill"; name .headline; "N exercises"; right column "Created" + date;
          .whiteCardStyleWithBorder(12, 16).
    TO:   .appCard(cornerRadius: 22, padding: 14), HStack(spacing 12):
          EmojiTile("🏋️", 46, AppPalette.accentSoft) |
          VStack(alignment: .leading, spacing 2):
             Text(workout.name).font(.appCardTitle).lineLimit(1)
             Text("\(n) exercises · Created \(d MMM)").font(.appSubtitle).foregroundColor(AppPalette.muted)
          | Spacer | Image("chevron.right") .system(size: 15, weight: .bold) AppPalette.muted.opacity(0.7)
    Remove the separate "Created" column. Date format "d MMM" (e.g. "25 Oct").

13. Leave the empty state (ContentUnavailableView) as is for now.

DONE WHEN
- With the plan from the screenshot (Upper 2/5, Lower 1/5, Abs 1/5) the card shows "1 of 15 sessions done",
  Lower or Abs is highlighted as UP NEXT with a full-width black "Start workout" button, Upper has an outlined Start.
- The chevron collapses/expands the card with a spring and the state survives an app relaunch.
- Swipe to share/delete on custom workouts still works; sort menu still works; tapping Start opens WorkoutDetailView.
- Light and dark mode both look right (ink buttons invert in dark mode — that is expected).
````

---

## Prompt 2 — Workouts tab (workout in progress)

````text
You are working in the Progress iOS app (SwiftUI). Prompts 0 and 1 are done: AppTheme.swift exists and the
Workouts tab uses it. Read AppTheme.swift, WorkoutListView.swift, TrainingPlanCard.swift, WorkoutRowView.swift,
and Progress/Core/Models/Workout.swift (status, isInProgress, startedAt, exercises; Exercise.isCompleted).

GOAL
When a workout has been started but not finished (workout.status == .inProgress), the Workouts tab must make
that obvious and offer one-tap resume.

RULES
- No model changes. Detect state with existing fields only.
- Use AppTheme components/colours only. Respect Reduce Motion for the pulsing dot.
- Do not change how a workout is started, completed or cancelled.

CHANGES — FROM → TO

1. Detect the active workout (WorkoutListView)
   FROM: nothing.
   TO:   private var activeWorkout: Workout? =
           allWorkouts.filter { $0.isInProgress && !$0.isDeleted }.max(by: startedAt ascending)
         This covers both plan workouts and custom workouts (allWorkouts is already queried).

2. New file Progress/Features/Workouts/Views/Components/ActiveWorkoutCard.swift
   Shown as the FIRST List row, above TrainingPlanCard, only when activeWorkout != nil.
   Card: VStack(alignment: .leading, spacing 14), padding 18,
         RoundedRectangle(26, .continuous).fill(AppPalette.ink), shadow black 0.30 radius 17 y 14.
         All text on it uses AppPalette.onInk (secondary text: onInk.opacity(0.7)).
   Top HStack(alignment: .top, spacing 12):
     - EmojiTile(planEmoji(for: name), 46, background: AppPalette.onInk.opacity(0.10))
     - VStack(alignment: .leading, spacing 4):
         HStack(spacing 6): 8pt Circle fill AppPalette.live with a soft pulsing halo (scale 1→1.8, opacity 0.35→0,
                            1.4s repeatForever; static when accessibilityReduceMotion)
                            + Text("IN PROGRESS").font(.appEyebrow).tracking(1).foregroundColor(AppPalette.live)
         Text(workout.name).font(.system(size: 20, weight: .heavy))
         Text("Exercise \(current) of \(total) · \(currentExerciseName)").font(.appSubtitle)
            current = index of the first exercise where !isCompleted (1-based), in the same order WorkoutDetailView
            lists exercises; if all are complete show "All exercises done".
     - Spacer
     - VStack(alignment: .trailing): elapsed time .system(size: 24, weight: .heavy).monospacedDigit(),
                                     Text("elapsed") 11 bold, onInk 0.7.
         Elapsed = now − startedAt, inside TimelineView(.periodic(from: .now, by: 1)); format m:ss under an hour,
         h:mm:ss after.
   Segment bar: HStack(spacing 4) of equal-width Capsules, height 5, one per exercise:
         completed → AppPalette.brandLight, current → AppPalette.onInk, upcoming → AppPalette.onInk.opacity(0.18).
   Button: Text("Resume workout") + Image("arrow.right") .buttonStyle(AppPillButtonStyle(.inverse, .large)).
   Action: navigate to WorkoutDetailView(workout:) using the same navigationDestination(item:) WorkoutListView already
           uses for plan workouts (rename planWorkoutToOpen → workoutToOpen if it reads better).
   Accessibility: the card is one element: "Workout in progress, \(name), exercise \(current) of \(total),
                  \(elapsed) elapsed". Button label "Resume workout".

3. Plan card while a workout is in progress (TrainingPlanCard)
   FROM: expanded/collapsed purely from @AppStorage.
   TO:   pass activeWorkoutId: UUID? in. When it is non-nil, the card shows COLLAPSED by default (a session-only
         @State override; do NOT write to the stored preference). The chevron still expands it.
   Collapsed pills: the pill for the active workout becomes
         HStack(spacing 5){ 6pt Circle AppPalette.live; Text("\(emoji) \(name) · live") } 12 heavy,
         foreground AppPalette.liveText, Capsule fill AppPalette.tint(AppPalette.live).
   Expanded rows: while a workout is active NO row gets the up-next treatment. The active plan workout's row shows
         a green "IN PROGRESS" badge (same shape as UP NEXT, fill AppPalette.live) and a compact
         AppPillButtonStyle(.ink, .compact) "Resume" button instead of "Start". Other rows keep the outlined Start.

4. Custom workout row while in progress (WorkoutRowView)
   FROM: chevron on the right.
   TO:   when workout.isInProgress, replace the chevron with a pill: 6pt live dot + "In progress", 12 heavy,
         AppPalette.liveText on AppPalette.tint(AppPalette.live), Capsule, padding h10 v6.

5. Tab bar
   No change. (The mockup's green dot on the Workouts tab is NOT built: the system TabView can only show red
   text badges, and we are keeping the native tab bar.)

DONE WHEN
- Start any workout, go back to the Workouts tab: the dark "IN PROGRESS" card is at the top with a live-ticking
  timer, the right exercise count, and "Resume workout" reopens that workout.
- The plan card is collapsed with a green "· live" pill; expanding it shows "IN PROGRESS" + Resume on that row.
- Finish or cancel the workout: the card disappears and the plan card returns to the stored expanded state.
- Reduce Motion on: the dot does not pulse. Dark mode: the card renders light-on-dark inverted and stays readable.
````

---

## Prompt 3 — Journey tab

````text
You are working in the Progress iOS app (SwiftUI). Prompt 0 added Progress/Resources/DesignTokens/AppTheme.swift
(AppPalette, AppBackground, appCard, appFloatingChip, EmojiTile, CircleIconButton, ChevronToggleButton,
AppProgressBar, AppPillButtonStyle, Font.app*). Read it first. Then read:
- Progress/Features/ProgressDashboard/Views/ProgressDashboardView.swift
- Progress/Features/ProgressDashboard/Views/DailyStepsCard.swift
- Progress/Features/ProgressDashboard/Views/WeightTrendCard.swift
- Progress/Features/Workouts/Views/Components/BodyMapSection.swift

RULES
- Keep all data logic: DashboardData, HealthKit steps, weight logging sheet, body-map colouring, legend sheet,
  achievement definitions and the achievement detail panel. Keep the existing @AppStorage expand keys
  (journey.dailySteps.expanded, journey.weightTrend.expanded, journey.bodyMap.expanded) and their animations.
- Use AppTheme only. No .largeTitle, whiteCardStyle or journeyCardStyle left in these files.
- Screen horizontal padding 20 (was 24). Gap between cards 12.

CHANGES — FROM → TO

1. Page content and order (ProgressDashboardView.body)
   FROM: JourneyHeroCard → StreakCardsView → DailyStepsCardView → WeightTrendCard → BodyMapSection
         (or EmptyJourneyCallToAction) → AchievementsRowView.
   TO:   DailyStepsCardView → WeightTrendCard → BodyMapSection (or EmptyJourneyCallToAction) → AchievementsRowView.
         REMOVE JourneyHeroCard (the "Me" profile card) and StreakCardsView ("Foods logged" / "This week")
         from the page. Delete those structs only if a project-wide search shows nothing else uses them.
   Background: AdaptiveGradientBackground() → AppBackground().

2. Header (ProgressDashboardView)
   FROM: Text("Journey") .largeTitle bold; one Button combining a gear icon and the membership-label capsule.
   TO:   HStack(spacing: 8):
         - Text("Journey").font(.appScreenTitle).tracking(-0.5).foregroundColor(AppPalette.ink)
         - Spacer
         - Streak chip (moved here from the removed hero card): Text("🔥 \(dashboardData.currentStreak)")
           .system(size: 15, weight: .heavy), height 36, padding h12, Capsule fill AppPalette.surface +
           strokeBorder AppPalette.line 1. Not a button. accessibilityLabel "\(n) day streak".
         - Membership pill: Text(subscriptionService.membershipLabel) .system(size: 14, weight: .heavy),
           height 36, padding h12, Capsule.
             subscribed:     fill AppPalette.accentSoft, text Color.brand
             not subscribed: fill AppPalette.optionFill, text AppPalette.muted
           It is a Button that opens Settings (same as today). NO chevron — it is a membership label, not a filter.
         - CircleIconButton("gearshape", .plain, 38, label "Settings") → showingSettings = true
         Padding horizontal 20, top 12, bottom 12.

3. Card style (all four widgets)
   FROM: journeyCardStyle() = whiteCardStyle(cornerRadius: 14, padding: 14) — note it is declared twice
         (ProgressDashboardView.swift and DailyStepsCard.swift); WeightTrendCard and BodyMapSection call
         whiteCardStyle(cornerRadius: 14, padding: 14) directly.
   TO:   steps, weight, achievements → .appCard(cornerRadius: 22, padding: 14)
         body map                    → .appCard(cornerRadius: 26, padding: 14)
         Delete both private journeyCardStyle extensions.

4. Card header (JourneyCardHeader)
   FROM: 24pt SF Symbol in a tinted RoundedRectangle(7); title .subheadline semibold; trailing text in a grey capsule.
   TO:   change the API to JourneyCardHeader(emoji: String, tint: Color, title: String, trailing: …) and update every call site:
         HStack(spacing 10): EmojiTile(emoji, size: 34, background: AppPalette.tint(tint)) |
         Text(title).font(.appCardTitle) | Spacer | trailing content.
   Emoji/tint per card: Daily steps "🚶" .orange · Body weight "⚖️" .purple · Body map "🧍" Color.brand ·
                        Achievements "🏆" .yellow.

5. Daily steps (DailyStepsCard.swift)
   FROM: progress bar colour changes with percentage (orange from 80%); chevron is a bare glyph.
   TO:   collapsed row: header + trailing Text("8,222") 15 heavy + Text("/ 10k") 13 bold muted (use the real
         steps/goal; abbreviate goals ≥ 1,000 as "10k") + ChevronToggleButton(size 30, existing labels).
         Bar: AppProgressBar(progress: steps / goal, height: 8), always the brand gradient.
         Expanded content (chart etc.) unchanged except: chart bar/line colours → Color.brand / AppPalette.brandLight.

6. Body weight (WeightTrendCard.swift)
   FROM: value text, "plus" glyph, chevron glyph.
   TO:   header trailing: value chip HStack{ Text("69.8") 15 heavy; Text("kg ↘") 13 bold muted } in Capsule
         fill AppPalette.optionFill, padding h10 v6 (keep the existing unit and trend-arrow logic) |
         CircleIconButton("plus", .ink, 32, label "Log weight") → existing log-weight action |
         ChevronToggleButton(size 30, existing labels).
         Inside the expanded chart: line colour Color.brand. Keep the green/orange meaning of the change text.

7. Body map (BodyMapSection.swift)
   FROM: whiteCardStyle header with legend button and chevron.
   TO:   header: JourneyCardHeader("🧍", Color.brand, "Body map") trailing:
         Button("Legend").buttonStyle(AppPillButtonStyle(.outline, .compact)) at height 30 (opens ProgressLegendView
         as today) + ChevronToggleButton(size 30).
         Map rendering and its data-driven colours: UNCHANGED. Do not use the onboarding demo colours here —
         the Journey map shows real training data.
         NEW, expanded state only: two .appFloatingChip() overlays on the map.
           top-leading (offset x 6, y 8):     Text(top1.displayName) 14 heavy + Text("on fire") 11 bold muted
           bottom-trailing (offset x -6, y -8): Text(top2.displayName) 14 heavy + Text("lighting up") 11 bold muted
         top1/top2 = the two muscle groups with the highest training value in the same data BodyMapSection already
         uses to colour the map. Omit a chip when there is no data for it. accessibilityHidden on the chips is NOT
         wanted — label them "Most trained: \(group)".

8. Achievements (AchievementsRowView + AchievementBadge)
   FROM: header with "7/26" capsule; badges in a horizontal ScrollView.
   TO:   header: JourneyCardHeader("🏆", .yellow, "Achievements") trailing: Text("\(unlocked)") 14 heavy +
         Text(" / \(total)") 14 bold muted + Image("chevron.right") 14 bold muted.
         Keep the horizontal ScrollView, selection and AchievementDetailPanel.
         AchievementBadge: 58pt circle, title under it (11 bold, centred, max 2 lines, width 72).
           unlocked: fill LinearGradient(achievement.color.opacity(0.14) → achievement.color.opacity(0.30), topLeading→bottomTrailing),
                     strokeBorder AppPalette.surface 2pt, shadow achievement.color.opacity(0.22) radius 7 y 6,
                     SF Symbol achievement.icon 24pt semibold in achievement.color.
           locked:   fill AppPalette.optionFill, strokeBorder AppPalette.line 2pt dash [4, 4],
                     "lock.fill" 20pt AppPalette.muted, title colour AppPalette.muted.
           selected: keep the current selection indication, recoloured to Color.brand.

9. Bottom spacing: keep a 32pt clear spacer (plus the system tab bar inset) so the last card clears the tab bar.

DONE WHEN
- Journey shows, top to bottom: header (Journey · 🔥 streak · membership pill · gear), Daily steps, Body weight,
  Body map, Achievements. No profile card, no Foods logged / This week cards.
- Steps, weight and body map still expand/collapse with animation and remember their state across launches.
- "+" on weight still opens the weight log; Legend still opens the legend sheet; achievements still show details.
- Light and dark mode correct; VoiceOver reads the streak chip and the expand buttons sensibly.
````

---

## Prompt 4 — Nutrition tab

````text
You are working in the Progress iOS app (SwiftUI). Prompt 0 added Progress/Resources/DesignTokens/AppTheme.swift
(AppPalette, AppBackground, appCard, EmojiTile, CircleIconButton, AppPillButtonStyle, Font.app*). Read it first.
Then read:
- Progress/Features/Nutrition/Views/NutritionDashboardView.swift
- Progress/Features/Nutrition/Views/Components/DayPickerCard.swift
- Progress/Features/Nutrition/Views/Components/CalorieCard.swift
- Progress/Features/Nutrition/SwipeableNutritionMetrics.swift (NutritionMetricCard, WaterMiniCard, page dots)
- Progress/Features/Nutrition/Views/Components/SwipeableNutritionRow.swift and SimpleFoodEntryRow.swift
- Progress/Features/Navigation/Components/FloatingAddButton.swift

RULES
- Keep all data and behaviour: week swipe gesture and its limits, selected-date logic, totals, goals,
  swipe-to-delete on food rows, photo thumbnails/analysing state, and every sheet (camera AI, describe, manual, water).
- The system tab bar is untouched and must look identical on every tab.
- Use AppTheme only. No .largeTitle or whiteCardStyle/whiteCardStyleWithBorder left in these files.
- Screen horizontal padding 20 (was 24).

CHANGES — FROM → TO

1. Background: AdaptiveGradientBackground() → AppBackground().

2. Header (NutritionDashboardView)
   FROM: Text("Nutrition") .largeTitle bold, padding h24 top16 bottom24.
   TO:   Text("Nutrition").font(.appScreenTitle).tracking(-0.5).foregroundColor(AppPalette.ink), leading-aligned,
         padding h20 top16 bottom8. NO date, NO buttons in the header.

3. Day picker (DayPickerCard)
   FROM: height 50, RoundedRectangle(12); selected = Color.primary fill; today = primary 10% fill + 2pt outline;
         letter .caption2 medium; number .headline bold.
   TO:   height 62, RoundedRectangle(18, .continuous).
         letter: .system(size: 12, weight: .bold); number: .system(size: 18, weight: .heavy, design: .rounded).
         selected: fill AppPalette.ink, letter AppPalette.onInk.opacity(0.75), number AppPalette.onInk,
                   shadow black 0.22 radius 8 y 6.
         unselected: clear fill, letter AppPalette.muted, number AppPalette.ink.
         today (when not selected): no outline — a 5pt Color.brand dot under the number.
         Container height in dayPickerHeader 74 → 86; row padding h16 → h14.

4. Calorie card (CalorieCard)
   FROM: whiteCardStyle(16, 20); 36pt bold number; "Calories left" with inline orange flame "+consumed";
         56pt orange ring.
   TO:   .appCard(cornerRadius: 24, padding: 18). HStack(spacing 8):
         VStack(alignment: .leading, spacing 6):
           Text(remaining).font(.system(size: 36, weight: .heavy, design: .rounded)).monospacedDigit()  (format with grouping: "2,414")
           Text("Calories left").font(.system(size: 14, weight: .semibold)).foregroundColor(AppPalette.muted)
           chip: Text("🍽 \(Int(consumed)) eaten") 12 bold, AppPalette.ink.opacity(0.75), Capsule AppPalette.optionFill, padding h9 v4
              (the existing "+N" is calories EATEN, so label it "eaten", not "burned")
         Spacer
         Ring 78pt: track Circle stroke AppPalette.accentSoft lineWidth 8; progress trim stroke
           AngularGradient(colors: [Color.brand, AppPalette.brandLight, Color.brand]) lineWidth 8 round cap, rotated −90°;
           centre: Circle fill AppPalette.surface 62pt with Text("🔥") 24pt. Keep the existing progress animation.

5. Water mini card (WaterMiniCard)
   FROM: whiteCardStyle.
   TO:   .appCard(cornerRadius: 24, padding: 14). Keep the cup/wave animation, recolour the water fill to
         AppPalette.brandLight and the cup outline to Color.brand.opacity(0.35). Value .system(size: 15, weight: .heavy);
         "Water" .system(size: 12, weight: .semibold) muted.

6. Macro cards — page 1 only (NutritionMetricCard for protein, carbs, fat)
   FROM: whiteCardStyle(16); SF Symbol metric.icon inside a ring tinted metric.color.
   TO:   .appCard(cornerRadius: 22, padding: 14 vertical / 8 horizontal), VStack(spacing 8), centred:
         Text("112g") .system(size: 20, weight: .heavy, design: .rounded) | Text("Protein left") 12 semibold muted |
         ring 50pt lineWidth 5: track hue.opacity(0.22), progress hue, round cap; centre Text(emoji) 18pt.
         protein → "🥩" AppPalette.protein · carbs → "🍞" AppPalette.carbs · fat → "🥑" AppPalette.fat.
   Page 2 (secondary metrics): same card container and fonts, but KEEP their SF Symbols and metric.color.

7. Page dots (SwipeableNutritionMetrics)
   FROM: two 8pt circles, Color.primary / Color.primary.opacity(0.3).
   TO:   active: Capsule 20×7 AppPalette.ink; inactive: Circle 7×7 AppPalette.muted.opacity(0.4);
         animate the width change with .spring(response: 0.3, dampingFraction: 0.8).

8. Food section header (NutritionDashboardView)
   FROM: Text(isToday ? "Today's Food" : "Food") .headline.
   TO:   HStack(alignment: .firstTextBaseline): Text(isToday ? "Today's food" : "Food").font(.appSectionTitle) |
         Spacer | Text("\(Int(totalCalories)) kcal") 14 bold muted (sum of selectedDateEntries.totalCalories).

9. ONE shared add-food menu (NutritionDashboardView)
   Extract the four existing menu items (Take Photo (AI), Describe Food, Enter Manually, Log Water — same icons,
   haptics and sheet flags) into a single @ViewBuilder `addFoodMenuItems`. Both entry points below use it, so they
   can never drift apart.

10. Empty state (emptyFoodMessage)
    FROM: centred fork.knife green circle, "No food logged yet", "Use the + button to add food", whiteCardStyle(16, 20).
    TO:   .appCard(cornerRadius: 24, padding: 20), HStack(spacing 14):
          EmojiTile("🍽️", size: 56, background: AppPalette.tint(.green)) |
          VStack(alignment: .leading, spacing 3):
             Text("Log your first meal") .system(size: 17, weight: .heavy)
             Text("Snap a photo, describe it or enter it manually.") 14, AppPalette.muted
          | Spacer(minLength: 0) |
          Menu { addFoodMenuItems } label: 48pt Circle AppPalette.ink with Image("plus") 22 bold AppPalette.onInk,
          shadow black 0.25 radius 8 y 6; accessibilityLabel "Log food".

11. Food list (foodEntriesList + rows)
    FROM: LazyVStack(spacing 12) of SwipeableNutritionRow, each .whiteCardStyleWithBorder(16).
    TO:   keep one swipeable card per entry (swipe-to-delete needs it), restyled .appCard(cornerRadius: 20, padding: 12):
          photo thumbnail 46×46 RoundedRectangle(14) (or EmojiTile("🍽️", 46, AppPalette.tint(.green)) when no photo);
          name 15 heavy; detail line 12 semibold muted; "logged from photo" indicator AppPalette.liveText with "📸";
          calories 15 heavy on the right. Keep the analysing-photo state.
          AFTER the last row, always: a "Log food" Menu { addFoodMenuItems } whose label is
            HStack(spacing 10){ 32pt Circle AppPalette.ink + Image("plus") 16 bold onInk; Text("Log food") 15 bold AppPalette.ink }
            frame maxWidth .infinity, height 56, background RoundedRectangle(20, .continuous) fill AppPalette.surface.opacity(0.6),
            overlay strokeBorder AppPalette.muted.opacity(0.5) lineWidth 1.5 dash [6, 4].

12. Remove the floating button
    FROM: .overlay(alignment: .bottom) { FloatingAddButton { … } } and bottom padding 88 "for the floating add button".
    TO:   delete that overlay; bottom padding 120 so the last element clears the tab bar.
          Leave FloatingAddButton.swift in the project if anything else uses it; delete it if nothing does.

DONE WHEN
- No date in the header; selected day is a black pill; today shows a blue dot.
- Empty day: one card "Log your first meal" with a black + that opens the 4-option menu.
- Day with food: rows, then a dashed "Log food" button under the last row, opening the same menu.
- The tab bar does not move or change when switching to Nutrition.
- Week swipe, swipe-to-delete, all four sheets, and the second metrics page still work. Light + dark mode correct.
````

---

## Prompt 5 — Polish and QA pass

````text
You are working in the Progress iOS app (SwiftUI). Prompts 0–4 restyled the Workouts, Journey and Nutrition tabs
using Progress/Resources/DesignTokens/AppTheme.swift. Do a verification and cleanup pass. Do not redesign anything.

1. Search these folders: Features/Workouts/Views (list screen + components touched in prompts 1–2),
   Features/ProgressDashboard/Views, Features/Workouts/Views/Components/BodyMapSection.swift, Features/Nutrition.
   Report and fix any remaining: Color.blue, Color(.systemGray6), .largeTitle, whiteCardStyle(,
   whiteCardStyleWithBorder(, journeyCardStyle(, AdaptiveGradientBackground() on the three tab root views,
   hard-coded hex colours that are not in AppPalette. (Workout detail, sheets and settings are out of scope — leave them.)
2. Dark mode: every new surface uses AppPalette dynamic colours. Fix anything that is invisible or low-contrast in dark mode.
3. Dynamic Type: at the largest non-accessibility size, nothing truncates mid-word in headers, plan rows, macro cards
   or the active workout card. Allow .minimumScaleFactor(0.8) on big numbers only.
4. VoiceOver: icon-only buttons have labels; expand/collapse buttons announce state; emoji tiles are hidden from
   VoiceOver; the active workout card reads as one sentence.
5. Reduce Motion: the in-progress pulse is static.
6. Previews: add/repair #Preview for TrainingPlanCard (expanded, collapsed, with active workout),
   ActiveWorkoutCard, ProgressDashboardView, and NutritionDashboardView (empty and with entries), each in light and dark.
7. Build with zero new warnings. List every file you changed and anything you could not resolve.
````
