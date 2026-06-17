# Smart Ambulance System - Frontend 🚑❤️

A modern, highly polished, and responsive Flutter registration and sign-in interface designed for healthcare staff and patients. It incorporates clinical styling, custom graphics, and smart validation animations.

## Key Features 🌟

- **Dynamic ECG Heartbeat Animation**: A custom-drawn, real-time animated ECG pulse line in the header indicating active system health.
- **Interactive Password Strength Meter**: Evaluates and color-codes password safety on a scale from 1 (Weak, Red) to 4 (Strong, Green) dynamically as the user types.
- **Real-Time Input Validation**: Instantly shows inline validation status (checkmarks for success, error message callouts for issues) upon form submission.
- **Custom Google OAuth button**: Features a manually painted, high-fidelity vector Google "G" logo without requiring heavy external image assets.
- **Harmonious Clinical UI**: Curated HSL-tailored color palette with a Deep Navy (`#0A3D5C`) clinical header and Emergency Red (`#E63946`) primary elements, powered by Google Fonts (Space Grotesk & DM Sans).

---

## Project Structure 📁

- [lib/main.dart](file:///c:/Users/dilna/OneDrive/Desktop/specialization%20project/lib/main.dart): Contains the entry point and the complete, responsive `AuthScreen` along with the custom UI painters:
  - `GoogleLogoPainter`: Renders the Google logo via vector coordinates.
  - `ECGPainter`: Animates a realistic ECG waveform line.
- [pubspec.yaml](file:///c:/Users/dilna/OneDrive/Desktop/specialization%20project/pubspec.yaml): Configures metadata and dependencies (`google_fonts`, `cupertino_icons`).

---

## Setup & Running Locally 🚀

### Prerequisites
Make sure you have Flutter installed on your machine (`sdk >= 2.19.0`).

### Steps
1. Clone this repository to your local machine.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
