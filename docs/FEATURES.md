# Gym Rank Features

This document provides a comprehensive guide to the core functionalities of the **Gym Rank** application and their underlying technical implementation.

---

## 🏗️ Mandatory Onboarding & Admin-Managed Gyms

To maintain data integrity and security, Gym Rank enforces a rigorous onboarding flow.

### Onboarding Flow logic
1.  **Auth Entry**: After Firebase Auth (Email/Google), the user is greeted by `AuthWrapper`.
2.  **Smart Verification**: The app checks local state **first**. If incomplete, it initiates a **Remote Profile Sync** to prevent redundant onboarding requests for existing users.
3.  **Completion Screen**: Users are redirected to `CompleteProfileScreen`, where they must set:
    -   **Name**: Their identity within the app.
    -   **Metrics**: Weight and Height (used for ELO and AI recommendations).
    -   **Primary Goal**: Their training focus (Build Muscle, Lose Fat, etc.).
    -   **Home Gym Selection**: Users must pick from a verified list of gyms.
4.  **Instant Release**: Once `saveProfile` is called, the app is unlocked.

---

## 🛡️ Admin Dashboard & User Management

Administrators have access to a comprehensive command center for managing the platform's health.

### User Directory
Accessible only to users with the `isAdmin` flag, this tool allows for:
-   **Manual Role Promotion**: Admins can grant or revoke `isAdmin`, `isGymOwner`, and `isGymTrainer` status.
-   **Account Actions**: Suspend/Ban users for policy violations.
-   **Gym Ownership/Staffing**: Assign specific users as "Gym Owners" or "Gym Trainers", and link them to their managed establishments.
-   **Global Console Overpass**: Users with `isAdmin: true` can access both the Owner and Trainer consoles for any facility, bypassing ownership checks for debugging and maintenance.

### Gym Management
A centralized hub for:
-   **Location Creation**: Add new official gym locations to the global database.
-   **Location Maintenance**: Edit or remove addresses and gym metadata.

---

## 🏢 Gym Owner Console
Specifically designed for the business owners and operations managers of a location.
### Accessibility
Visible under **Profile & Settings** if the user document boolean `isGymOwner` is true OR if the user is a global `isAdmin`.
### Key Tools
-   **Business Analytics**: High-level views of total members, pro member conversion rates, and the gym's collective athlete ELO.
-   **Member Directory**: An overview list of registered members focusing on their subscription tiers.
-   **Real-time Permissions**: Access is granted immediately upon role promotion; the profile screen syncs from remote on initialization.

---

## 🏋️ Gym Trainer Console
Specifically designed for the fitness coaches managing athletes on the gym floor.
### Accessibility
Visible under **Profile & Settings** if the user document boolean `isGymTrainer` is true OR if the user is a global `isAdmin`.
### Key Tools
-   **Athlete Roster**: A list of every athlete registered to the location.
-   **Log Auditing (Member Detailed View)**: Tapping on any member grants the trainer **read-only historical access** to their workout sessions.
    -   **Visibility**: Trainers can view the member's profile overview (ELO, Subscription, Rank).
    -   **Audit Logs**: Expands individual workout sessions to show exact exercises performed, including sets, reps, and kg lifted, enabling targeted progressive overload coaching.
-   **Rank Monitoring**: View the distribution of rank tiers (SS to F) across the roster.

---

### System Analytics
Real-time tracking of:
-   **User Growth**: Daily and monthly registration trends.
-   **Engagement Score**: Average sessions per user.
-   **Sync Health**: Monitoring Firestore write throughput and error rates.

---

## 🤖 AI Coach: Personal Trainer in Your Pocket

The AI Coach is powered by **Gemini 1.5 Flash**, offering a sophisticated, context-aware training experience.

### Internal Prompt Structure
The coach doesn't just "chat"; it receives a dense **system prompt** containing:
-   **Full Athlete Context**: Name, Rank, ELO, Goal, and Metrics.
-   **Session History**: The last 5 workout sessions (Volume, Reps, Frequency).
-   **Expertise Guidelines**: Strength training, hypertrophy, and recovery.
-   **Coaching Persona**: "GymAI" — elite, motivational, and technical.

### Wizard Interaction Logic
-   **Contextual Initialization**: The `AiCoachService` re-initializes only if the context (profile/sessions) changes significantly.
-   **Streaming Responses**: Using `sendMessageStream` to provide zero-latency text chunking.
-   **Topic Boundaries**: Attempts to ask about non-fitness topics are redirected with a polite but firm "I'm only trained for fitness!" response.

---

## 👁️ AI Pose & Form Tracker: Biomechanical Coaching

The AI Pose Tracker uses **Computer Vision (Google ML Kit)** to transform the device's camera into a sophisticated motion analysis tool.

### 🔄 Rep Counting & Tempo
-   **EMA Smoothing**: Raw landmark data is processed via an **Exponential Moving Average** (alpha=0.25) to remove camera jitter.
-   **Hysteresis State Machine**: Precise rep counting using a dual-threshold hysteresis model (e.g., triggering "Up" at 160° and "Down" at 90°) to prevent double-counting from small movements.
-   **Tempo Analysis**: Tracks the duration of **Concentric** and **Eccentric** phases, rewarding a controlled 1:2 or 1:3 ratio.

### ⚖️ Biomechanical Form Analysis
-   **Exercise-Specific Rules**: The `FormAnalyzer` evaluates 7+ exercises (Squat, Push-up, Bicep Curl, etc.) against professional standards.
-   **3D Geometry**: Calculates joint angles and relative positions (e.g., Knee-over-toe, Elbow drift).
-   **Z-Axis Depth Analysis**: Detects errors invisible in 2D, such as **Hip Sag** in push-ups or **Forward Lean** in squats, by monitoring relative Z-coordinates.

### 🎯 Calibration & Personalization
-   **Neutral Pose Baseline**: Users perform a 2-second "Neutral Hold" to calibrate the system to their specific limb lengths and the camera's perspective.
-   **Scaling**: Analysis is normalized based on the user's shoulder and hip width captured during calibration.

### 🏮 Live Feedback & Fatigue
-   **Joint Coloring**: The on-screen skeleton highlights incorrect joints in **Red/Orange** and perfect ones in **Green**.
-   **Fatigue Detection**: Monitors velocity and quality decay over the last 3 reps to warn of impending form breakdown.
-   **TTS Integration**: Real-time voice coaching for rep counts, phase changes, and corrective feedback.

---

## 🏆 Gamification: ELO & Rank Tiers

Gym Rank converts workout volume into a competitive **ELO Score** (0–999) using a logarithmic growth curve.

### Rank Tiers
Levels are categorized from **F** to **SS**, rewarding consistency and progressive overload.
-   **Rank SS (ELO 900+)**: Elite Athlete
-   **Rank S (ELO 800-899)**: Professional
-   **Rank A (ELO 600-799)**: Advanced
-   -   *(Lower Tiers: B, C, D, E, F)*

### Progressive Overload Tracking
The app tracks "Best Volume" per exercise. Your rank increases as you lift more weight, perform more reps, or increase training frequency.

---

## 🗺️ Visual Analytics: Muscle Heatmap & Radar

Data visualization is key to identifying weak points.

### Radar Chart (0–100 Score)
The Radar chart compares your sets across 10 major muscle groups.
-   **Normalization**: Each muscle's score is calculated as a percentage of your **max volume** from any single muscle group.
-   **Goal**: A perfectly balanced athlete has 100 in all areas.

### Real-Time Recovery Heatmap
Located on the dashboard, this interactive body map uses color-coded visual cues (Red/Yellow/Green) based on the **Supercompensation 72-hour Model** to show which muscles are ready for another session.
