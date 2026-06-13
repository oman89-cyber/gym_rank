# 🏋️ GymRank — Gamified Fitness RPG

> **"Track Lifts. Rank Up. Compete Globally."**  
> A full-stack Flutter + Firebase fitness platform that turns your gym sessions into an RPG experience.

---

## 📖 What is GymRank?

GymRank is a **gamified workout tracker** built with Flutter. Users log workouts, earn an **ELO-based rank** (F → SS), track muscle recovery, compete on a leaderboard, get AI coaching from Gemini, and even have their **exercise form analysed in real-time** via the device camera and ML Kit Pose Detection.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart `>=3.2.0`) |
| **State Management** | Riverpod (`flutter_riverpod ^2.5.1`) |
| **Backend / Database** | Firebase Firestore + Firebase Auth |
| **Local Storage / Cache** | Hive (`hive_flutter`) |
| **AI Coach** | Google Generative AI (Gemini) |
| **Pose Detection** | Google ML Kit (`google_mlkit_pose_detection`) |
| **UI / Animations** | `flutter_animate`, `confetti`, `shimmer` |
| **Fonts** | Google Fonts |
| **Notifications** | `flutter_local_notifications` |
| **Text-to-Speech** | `flutter_tts` |
| **Media** | `camera`, `image_picker`, `audioplayers` |

---

## 📁 Full Folder & File Structure

```
gym_rank/
├── lib/                        ← All Dart source code
│   ├── main.dart               ← App entry point (Firebase init, Riverpod, theme setup)
│   ├── firebase_options.dart   ← Auto-generated Firebase config (DO NOT edit manually)
│   │
│   ├── core/                   ← Shared, reusable code (no UI screens here)
│   │   ├── constants/
│   │   │   ├── mock_data.dart          ← Dummy/seed data for testing
│   │   │   └── exclusive_challenges.dart ← Hardcoded special challenge definitions
│   │   │
│   │   ├── models/             ← Plain Dart data classes (no Flutter deps)
│   │   │   ├── user_profile.dart       ← UserProfile class: rank, ELO, subscription, friends
│   │   │   ├── workout_session.dart    ← A single complete gym session
│   │   │   ├── logged_exercise.dart    ← One exercise within a session
│   │   │   ├── exercise_set.dart       ← One set (reps × weight) within an exercise
│   │   │   ├── challenge.dart          ← A global challenge definition
│   │   │   └── user_challenge.dart     ← A user's progress on a challenge
│   │   │
│   │   ├── providers/          ← Riverpod providers (state management)
│   │   │   ├── profile_provider.dart       ← Current user's profile (real-time local state)
│   │   │   ├── workout_providers.dart      ← Session history, active workout, ELO updates
│   │   │   ├── ai_coach_provider.dart      ← Gemini AI chat state & message history
│   │   │   ├── challenge_providers.dart    ← Active & completed challenge state
│   │   │   ├── friends_provider.dart       ← Friend list, search, add/remove logic
│   │   │   ├── leaderboard_provider.dart   ← Global leaderboard fetch
│   │   │   ├── exercise_library_provider.dart ← Exercises JSON lazy loader
│   │   │   ├── admin_providers.dart        ← Admin panel data (users, stats)
│   │   │   ├── gym_provider.dart           ← List of available gyms
│   │   │   └── repository_providers.dart   ← Wires up service implementations
│   │   │
│   │   ├── repositories/       ← Thin wrappers that own data fetch logic
│   │   │   ├── profile_repository.dart     ← load/save profile (Hive + Firebase)
│   │   │   ├── workout_repository.dart     ← load/save sessions & routines
│   │   │   └── gym_repository.dart         ← fetch gym list
│   │   │
│   │   ├── services/           ← Business logic & external integrations
│   │   │   ├── firebase_remote_service.dart ← Firestore CRUD (users, sessions, feed, leaderboard)
│   │   │   ├── remote_service.dart          ← Abstract interface for the remote backend
│   │   │   ├── auth_service.dart            ← Google Sign-In, sign out, user state stream
│   │   │   ├── ai_coach_service.dart        ← Gemini AI prompt builder & response parser
│   │   │   ├── live_coach_service.dart      ← WebSocket live coaching connection
│   │   │   ├── elo_service.dart             ← ELO score computation algorithm
│   │   │   ├── challenges_service.dart      ← Challenge progress evaluation logic
│   │   │   ├── exercise_library.dart        ← Loads + queries the exercises.json database
│   │   │   ├── notification_service.dart    ← Local push notifications scheduler
│   │   │   ├── persistence_service.dart     ← Hive box initializer
│   │   │   ├── recovery_service.dart        ← Muscle recovery % calculator
│   │   │   ├── storage_service.dart         ← Hive read/write wrapper for all entities
│   │   │   └── sync_service.dart            ← Background Hive → Firestore sync manager
│   │   │
│   │   ├── theme/
│   │   │   ├── app_colors.dart     ← All color constants (primary, rank colors, gradients)
│   │   │   └── app_theme.dart      ← MaterialTheme dark theme configuration
│   │   │
│   │   ├── utils/
│   │   │   └── muscle_mapper.dart  ← Maps exercise names → muscle group enum values
│   │   │
│   │   └── widgets/            ← Reusable UI widgets used across multiple features
│   │       ├── rank_badge.dart         ← Animated rank badge (F, E, D, C, B, A, S, SS)
│   │       ├── premium_card.dart       ← Glass-effect card for premium content
│   │       └── custom_painters.dart    ← CustomPainter classes (radar chart, XP bar, etc.)
│   │
│   ├── features/               ← Each folder = one full screen or feature area
│   │   │
│   │   ├── auth/
│   │   │   ├── auth_wrapper.dart       ← Route guard: decides Login vs Home vs Profile Setup
│   │   │   ├── login_screen.dart       ← Google Sign-In screen
│   │   │   └── suspended_screen.dart   ← Shown when user account is banned
│   │   │
│   │   ├── home/
│   │   │   ├── home_screen.dart        ← Main feed: posts, quick-start workout, friends activity
│   │   │   └── widgets/
│   │   │       ├── gym_ai_chat_screen.dart  ← Inline AI chat card on home screen
│   │   │       └── live_coach_screen.dart   ← Live coaching session widget
│   │   │
│   │   ├── workout/
│   │   │   ├── workout_screen.dart             ← Routine management + session launcher
│   │   │   ├── edit_workout_screen.dart        ← Create / edit a saved routine
│   │   │   ├── post_workout_summary_screen.dart ← ELO gained, muscles hit, confetti animation
│   │   │   └── widgets/
│   │   │       ├── active_session_view.dart    ← Real-time workout logging UI (sets, reps, weight)
│   │   │       ├── exercise_picker_sheet.dart  ← Searchable bottom sheet to pick exercises
│   │   │       ├── history_sheet.dart          ← Scrollable past sessions list
│   │   │       └── muscle_progress_sheet.dart  ← Per-muscle volume progress visualisation
│   │   │
│   │   ├── dashboard/
│   │   │   └── dashboard_sheet.dart    ← Analytics: volume charts, muscle radar, PRs, stats
│   │   │
│   │   ├── rank/
│   │   │   ├── rank_screen.dart        ← User's current rank, ELO progress, rank history
│   │   │   └── compare_screen.dart     ← Side-by-side ELO / stats comparison with a friend
│   │   │
│   │   ├── rank_assessment/
│   │   │   └── rank_assessment_screen.dart ← One-time onboarding quiz to set initial ELO
│   │   │
│   │   ├── ai_coach/
│   │   │   └── ai_coach_screen.dart    ← Full-screen Gemini AI chat (workout plans, form tips)
│   │   │
│   │   ├── pose_tracker/
│   │   │   ├── pose_tracker_screen.dart ← Full camera view with real-time form feedback
│   │   │   ├── models/
│   │   │   │   ├── calibration_data.dart   ← User body proportion calibration snapshot
│   │   │   │   ├── exercise_config.dart    ← Per-exercise angle thresholds & rules
│   │   │   │   ├── form_result.dart        ← Output of one form analysis cycle
│   │   │   │   ├── rep_result.dart         ← Output of one completed rep
│   │   │   │   └── workout_session.dart    ← Pose-tracker-specific session state
│   │   │   ├── services/
│   │   │   │   ├── pose_service.dart       ← ML Kit camera stream → landmark coordinates
│   │   │   │   ├── rep_counter.dart        ← Angle-based rep counting with hysteresis
│   │   │   │   ├── form_analyzer.dart      ← Biomechanical rules engine (3D angle checks)
│   │   │   │   ├── calibration_service.dart ← Captures user's neutral stance measurements
│   │   │   │   ├── fatigue_detector.dart   ← Detects declining rep speed = fatigue warning
│   │   │   │   └── tts_manager.dart        ← Voice feedback ("Good rep!", "Fix your back!")
│   │   │   └── widgets/
│   │   │       ├── skeleton_painter.dart   ← Draws coloured skeleton overlay on camera
│   │   │       ├── calibration_overlay.dart ← Calibration step UI overlay
│   │   │       └── stat_hud.dart           ← On-screen HUD: reps, sets, form score, timer
│   │   │
│   │   ├── leaderboard/
│   │   │   └── leaderboard_screen.dart ← Global ELO leaderboard (top 100 users)
│   │   │
│   │   ├── challenges/
│   │   │   └── challenges_screen.dart  ← Active challenges, progress bars, claim rewards
│   │   │
│   │   ├── friends/
│   │   │   └── friends_screen.dart     ← Search users, add friends, view friend profiles
│   │   │
│   │   ├── explore/
│   │   │   └── explore_screen.dart     ← Discover public workout posts / feed
│   │   │
│   │   ├── profile/
│   │   │   ├── profile_screen.dart             ← User's own profile page (stats, badges, history)
│   │   │   ├── complete_profile_screen.dart    ← Onboarding form (weight, height, goal, gym)
│   │   │   ├── subscription_screen.dart        ← Pro subscription / upgrade page
│   │   │   └── widgets/
│   │   │       └── rank_progress_bar.dart      ← Animated ELO progress bar widget
│   │   │
│   │   ├── trainers/
│   │   │   └── trainers_screen.dart    ← Browse and contact gym trainers
│   │   │
│   │   └── admin/                      ← Restricted to users with isAdmin = true
│   │       ├── admin_dashboard_screen.dart     ← Platform-wide stats overview
│   │       ├── admin_analytics_screen.dart     ← Pro/trial user counts, feed post stats
│   │       ├── user_management_screen.dart     ← Search all users, ban/unban, promote
│   │       ├── user_details_admin_screen.dart  ← Single user deep-dive (sessions, ELO, roles)
│   │       ├── gym_management_screen.dart      ← Add/remove gyms from the platform
│   │       ├── trainer_management_screen.dart  ← Assign trainers to gyms
│   │       ├── gym_owner_dashboard.dart        ← Dashboard for gym owner role
│   │       ├── gym_trainer_dashboard.dart      ← Dashboard for gym trainer role
│   │       └── gym_member_details_screen.dart  ← Gym-owner view of a specific member
│   │
│   └── navigation/
│       └── main_navigation.dart    ← Bottom tab bar (Home, Workout, Rank, Leaderboard, Profile)
│
├── assets/
│   ├── data/
│   │   └── exercises.json      ← ~1 MB exercise database (name, muscle group, equipment, GIF URL)
│   ├── rank_badge/             ← Rank badge images: A.png, B.png, C.png, D.png, E.png, F.png, S.png, SS.png
│   └── radar_images/           ← Muscle group radar chart images (abs, back, biceps, chest, etc.)
│
├── docs/                       ← Technical documentation (for developers)
│   ├── ARCHITECTURE.md         ← ELO algorithm, state flow diagrams, security design
│   ├── FEATURES.md             ← Full feature list by screen
│   ├── FILE_REFERENCE.md       ← Quick file → purpose reference
│   └── POSTURE_AI.md           ← Pose tracker technical deep-dive
│
├── android/                    ← Android platform project (auto-generated)
├── ios/                        ← iOS platform project (auto-generated)
├── web/                        ← Web platform project (auto-generated)
├── windows/                    ← Windows platform project (auto-generated)
├── test/                       ← Flutter unit & widget tests
│
├── firebase.json               ← Firebase Hosting & Firestore deploy config
├── firestore.rules             ← Firestore security rules
├── firestore.indexes.json      ← Compound Firestore index definitions
├── pubspec.yaml                ← Flutter dependencies & asset declarations
├── pubspec.lock                ← Locked dependency versions (commit this!)
└── analysis_options.yaml       ← Dart linting rules
```

---

## 🏆 Rank System (ELO-Based)

| Rank | Name | ELO Score |
|---|---|---|
| **F** | Newbie | 0 – 49 |
| **E** | Recruit | 50 – 149 |
| **D** | Strongman | 150 – 299 |
| **C** | Warrior | 300 – 499 |
| **B** | Adept | 500 – 799 |
| **A** | Elite | 800 – 1199 |
| **S** | Titan | 1200 – 1999 |
| **SS** | Ascended | 2000+ |

ELO is calculated from workout volume, weighted by muscle group multipliers (compound lifts score higher) and compressed with a sigmoid-like formula so early gains are fast but elite ranks take real dedication.

---

## 🧠 Key Features

| Feature | Description |
|---|---|
| **ELO Ranking** | Dynamic rank that updates after every session |
| **AI Coach** | Gemini-powered chat for plans, form tips, and motivation |
| **Pose Tracker** | Real-time form analysis via camera + ML Kit |
| **Challenges** | Time-limited global challenges with rewards |
| **Leaderboard** | Top 100 users worldwide by ELO |
| **Friends** | Add friends, compare stats, view their activity |
| **Dashboard** | Volume charts, muscle radar chart, PRs, session history |
| **Muscle Recovery** | Shows % recovery per muscle group since last session |
| **Admin Panel** | Full user management, ban/promote, gym management |
| **Gym Owner Panel** | View and manage members in your gym |
| **Offline Support** | Hive local cache — works without internet |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.2.0` installed ([flutter.dev](https://flutter.dev))
- A Firebase project with Firestore + Authentication (Google Sign-In) enabled
- Android Studio or VS Code with Flutter & Dart extensions

### Setup

```bash
# 1. Install all dependencies
flutter pub get

# 2. Run on a connected device or emulator
flutter run

# 3. To run on a specific platform
flutter run -d android
flutter run -d ios
flutter run -d windows
```

> **Note:** `lib/firebase_options.dart` is already configured for the existing Firebase project. If you connect a new Firebase project, re-run `flutterfire configure`.

---

## 🗄️ Firebase Collections

| Collection | Purpose |
|---|---|
| `users/{uid}` | User profile (ELO, rank, subscription, roles) |
| `users/{uid}/sessions` | All workout sessions for a user |
| `users/{uid}/routines` | Saved workout routines |
| `feed` | Global public workout posts |
| `gyms` | List of registered gyms |

---

## ⚠️ Security Notes

- **Firestore Rules** expire on **2026-05-03** — update `firestore.rules` with proper role-based rules before then!
- `isAdmin`, `isBanned`, and `subscriptionStatus` fields are **stripped from client writes** in `firebase_remote_service.dart` — only the server/admin panel can modify them.
- Admins are assigned manually in Firestore (`isAdmin: true`).

---

## 📦 Dependencies Summary

```yaml
flutter_riverpod     # State management
google_fonts         # Typography
flutter_animate      # Animations
shimmer              # Loading skeletons
hive_flutter         # Local offline storage
firebase_core        # Firebase base
cloud_firestore      # Database
firebase_auth        # Authentication
google_sign_in       # Google OAuth
google_generative_ai # Gemini AI
image_picker         # Photo selection
flutter_markdown     # Render markdown in AI responses
web_socket_channel   # Live coach WebSocket
audioplayers         # Sound effects
flutter_local_notifications  # Push notifications
camera               # Camera stream for pose tracking
google_mlkit_pose_detection  # AI pose landmark detection
flutter_tts          # Text-to-speech voice coaching
confetti             # Post-workout celebration animation
intl                 # Date formatting
uuid                 # Generate unique IDs
```

---

## 📚 Developer Docs

See the `/docs` folder for deep technical documentation:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — ELO algorithm, state flow, security design
- [`docs/FEATURES.md`](docs/FEATURES.md) — Complete feature breakdown
- [`docs/FILE_REFERENCE.md`](docs/FILE_REFERENCE.md) — Quick file reference guide
- [`docs/POSTURE_AI.md`](docs/POSTURE_AI.md) — Pose tracker ML pipeline details

---

*Built with ❤️ using Flutter & Firebase*
