# Gym Rank File Reference

This document maps every file in the **Gym Rank** project to its specific role and responsibility.

## 📁 Root Directory
- `pubspec.yaml`: Project dependencies (Riverpod, Firebase, Google Fonts, etc.).
- `firestore.rules`: Security rules for Cloud Firestore.
- `firebase.json`: Firebase configuration.
- `README.md`: High-level project overview.

---

## 📁 `lib/core` (System Core)

### 📂 `models/` (Data Entities)
- `user_profile.dart`: The global user entity (Username, ELO, Rank, Gym ID, Ban Status).
- `workout_session.dart`: Represents a completed workout or routine template.
- `logged_exercise.dart`: An exercise entry within a session, containing multiple sets.
- `exercise_set.dart`: Individual set data (Weight, Reps, RPE, Volume).
- `post.dart`: Feed post entity for social interactions.

### 📂 `providers/` (State Management)
- `repository_providers.dart`: Dependency injection for singleton services and repos.
- `profile_provider.dart`: Global state for the current user's profile and settings.
- `workout_providers.dart`: Manages active sessions, saved routines, and workout history.
- `social_providers.dart`: Handles the social feed, leaderboard, and friend lists.

### 📂 `repositories/` (Data Abstraction)
- `profile_repository.dart`: Local-first abstraction for user profile data.
- `workout_repository.dart`: Handles persistence and retrieval of local workout data.

### 📂 `services/` (Business Logic & External APIs)
- `auth_service.dart`: Interface for Firebase Authentication.
- `remote_service.dart`: API for all Firestore operations (User sync, Feed, Leaderboard).
- `firebase_remote_service.dart`: Implementation of `RemoteService` using Firebase SDK.
- `sync_service.dart`: Orchestrates data movement between Local (Hive) and Remote (Firestore).
- `elo_service.dart`: Logic for calculating Rank ELO from workout volume.
- `recovery_service.dart`: 72-hour muscle fatigue decay algorithm.
- `ai_coach_service.dart`: Gemini 1.5 Flash integration for the AI Coach.

### 📂 `widgets/` (Global UI Components)
- `app_logo.dart`: Branded logo with cyberpunk styling.
- `card_glow.dart`: Reusable neon-glow container effect.
- `muscle_selector.dart`: Interactive grid for selecting targeted muscle groups.

---

## 📁 `lib/features` (Domain Modules)

### 📂 `admin/`
- `admin_dashboard_screen.dart`: Central hub for administrator tasks.
- `gym_management_screen.dart`: Interface for managing the global `gyms` registry.
- `user_management_screen.dart`: Tool for searching, banning, and promoting users.

### 📂 `ai_coach/`
- `ai_coach_screen.dart`: Real-time chat interface with GymAI.

### 📂 `auth/`
- `auth_wrapper.dart`: Root widget that handles Login/Onboarding routing.
- `login_screen.dart`: Visual entry point for authentication.
- `complete_profile_screen.dart`: Mandatory onboarding form.

-   **complete_profile_screen.dart**: Mandatory onboarding form.

### 📂 `pose_tracker/`
-   **pose_tracker_screen.dart**: AI Vision interface with Camera preview, Skeleton overlay, and Live HUD.
-   **📂 models/**:
    -   `exercise_config.dart`: Definitions for angles, phases, and biomechanical thresholds.
    -   `form_result.dart`: Structure for localized joint feedback and coloring.
    -   `rep_result.dart`: Data entity for a single rep (Quality, Tempo, Form Note).
    -   `calibration_data.dart`: Normalized baseline for body proportions.
-   **📂 services/**:
    -   `pose_service.dart`: Camera controller & ML Kit pipeline.
    -   `rep_counter.dart`: EMA smoothing, hysteresis, and scoring state machine.
    -   `form_analyzer.dart`: Exercise-specific biomechanical rule engine.
    -   `calibration_service.dart`: Logic for capturing the neutral pose baseline.
    -   `fatigue_detector.dart`: Trend analysis for performance decay.
    -   `tts_manager.dart`: Debounced text-to-speech feedback.
-   **📂 widgets/**:
    -   `skeleton_painter.dart`: Custom painter for the 3D-aware pose overlay.
    -   `stat_hud.dart`: Real-time performance metrics (Quality, Reps, Feedback).
    -   `calibration_overlay.dart`: UI guide for the 2-second neutral hold.

### 📂 `social/`
- `social_feed_screen.dart`: Global community feed of completed workouts.
- `leaderboard_screen.dart`: Regional and Global ranking lists.
- `friend_list_screen.dart`: User's social circle and search.

### 📂 `workout/`
- `workout_screen.dart`: Main dashboard for starting and viewing workouts.
- `active_session_view.dart`: Work-in-progress session logger.
- `edit_workout_screen.dart`: Tool for modifying past sessions or routines.
- `widgets/history_sheet.dart`: Modal for viewing previous workout logs.
- `widgets/muscle_progress_sheet.dart`: Radar chart and volume analytics.
- `widgets/routine_selector.dart`: Selection list for saved training templates.
- `widgets/active_exercise_card.dart`: Interactive set-logger for live workouts.

---

## 📁 `lib/navigation`
- `main_navigation.dart`: Core Scaffold with the Bottom Navigation Bar and theme integration.
