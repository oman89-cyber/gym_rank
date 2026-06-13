# AI Posture & Form Analysis Deep-Dive

The **Gym Rank AI Posture Feature** is a specialized biomechanical engine designed to provide elite-level coaching previously only available through high-end sports laboratories. This document details the technical implementation and the logic behind the form analysis.

---

## 🏗️ 1. Technical Framework: Google ML Kit
The feature is built on top of **Google ML Kit Pose Detection**. Unlike standard 2D detection, Gym Rank utilizes the **landmark depth (Z)** to calculate true 3D spatial relationships.

### Landmarks Used
The system monitors **33 global landmarks**, with a primary focus on:
- **Major Joints**: Shoulders, Hips, Knees, Ankles, Elbows.
- **Support Points**: Wrists, Heels, Toes (used for gait and balance).

---

## 🧠 2. Repcounting Logic: The Hysteresis Model
To ensure accuracy and prevent "double counting" from jitter, the app uses a **Hysteresis State Machine**. 

### Rep Phases
- **IDLE**: Waiting for movement.
- **ECCENTRIC (DOWN)**: Movement towards the threshold.
- **CONCENTRIC (UP)**: Movement back to starting position.

### Hysteresis Example (Bicep Curl)
- **Effective Down Angle**: 160°
- **Effective Up Angle**: 90°
- **Hysteresis Buffer**: 10°
- **Logic**: A rep only "counts" if the user travels from below 100° (Up Threshold + Buffer) to above 150° (Down Threshold - Buffer), ensuring full range of motion.

---

## ⚖️ 3. Form Analysis: Exercise-Specific Rules
The `FormAnalyzer` implements professional coaching rules for each supported movement.

### 🏋️ Squat (The Golden Standard)
1. **Depth Detection**: Analyzes the relative Y-coordinate of the Hip vs. the Knee. If $Hip_y < Knee_y - \text{buffer}$, the depth is marked as "Insufficient".
2. **Knee Over Toe**: Monitors the X-distance between the Knee and Ankle. If the knee exceeds 15% of the total frame width beyond the ankle, a warning is triggered.
3. **Z-Lean Analysis**: Calculates the Z-depth difference between the Shoulder and the Hip. If the Shoulder moves significantly closer to the camera than the Hip, it indicates the athlete is "leaning forward" too much.

### 🤝 Push-Ups (Alignment Check)
1. **Hip Sag**: Uses the Z-axis to measure the distance of the Hip from the plane formed by the Shoulders and Ankles. High positive variance indicates a "sagging core."
2. **Body Alignment**: Calculated using a 3D dot product to ensure the Shoulder, Hip, and Ankle maintain an angle $> 165°$.

### 💪 Bicep Curls (Isolation Check)
1. **Elbow Drift**: Monitors the X-alignment of the Elbow relative to the Shoulder. Any variance $> 10\%$ indicates the user is using their shoulders to "cheat" the weight up.

---

## 🎯 4. Normalization via Calibration
Since every user has different limb lengths and camera setups differ, the system uses a **Normalization Layer**:
- **Baseline Capture**: Captures the vertical distance between shoulders and hips to establish a "meter-per-pixel" estimation.
- **Point-of-View Correction**: Normalizes depth (Z) relative to the primary torso plane.

---

## 📉 5. Fatigue Detection (Velocity Decay)
Fatigue is not just "failure"; it's the measurable decay in movement quality. The `FatigueDetector`:
1. Stores the **Concentric Velocity** of the last 3 reps.
2. Compares the average velocity of these reps to the **First 3 reps** (the fresh state).
3. If velocity drops by $> 30\%$, the AI Coach provides a "Form at Risk" warning via TTS.

---

## 🔉 6. Voice Guidance (TTS)
The `TtsManager` provides real-time debounced feedback:
- **Rep Counts**: "One... Two... Three..."
- **Phase Prompts**: "Up! Control the down."
- **Emergency Corrections**: "Knees in! Chest up!"
