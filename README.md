# Nulldle — Wordle-Style Flutter Puzzle Game

**Nulldle** is a Flutter-based word puzzle where players guess a hidden five-letter English word within six attempts.  
Each guess provides instant color feedback:
- Green: Correct letter and correct position  
- Yellow: Correct letter but wrong position  
- Grey: Letter not in the word  

---

## Features
- Clean, modular architecture using the Model-View-ViewModel (MVVM) pattern  
- Provider for smooth state management  
- Persistent statistics tracking wins, losses, and streaks  
- Improved gameplay logic: prevents duplicate guesses, fixes color feedback, and ensures stable dictionary loading  
- Optimized performance verified with Flutter DevTools  
- Fully responsive user interface and keyboard layout  

---

## Refactoring Highlights

| Issue Before Refactor | Solution After Refactor |
|------------------------|--------------------------|
| Game ended early after 5 attempts | Corrected to 6 tries |
| Incorrect color feedback (red instead of grey) | Updated logic for clarity |
| Crashes before dictionary loaded | Added loading guards |
| Reused words allowed | Added duplicate guess prevention |
| Code tightly coupled | Split into clean model-view-viewmodel structure |

---

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/nulldle.git
cd nulldle


2. Get Dependencies
flutter pub get

3. Run the App
flutter run


Performance Metrics
Metric	Description	Measured (ms)	Target	Outcome
Startup Time	Time for the first frame after app launch	398	≤ 500	Within target
Guess Submission	Time to validate and show result	0–1	≤ 5	Instant feedback
Record Win/Loss	Time to save statistics after game ends	1–5	≤ 10	Efficient
Load Statistics	Time to retrieve stored data	0	≤ 5	Excellent



Learning Outcomes

Strengthened understanding of state management and code refactoring

Applied clean architecture principles for improved maintainability

Gained experience in testing, UI optimization, and logic-UI separation

Author

Wilson Mugwe Gathii
Bachelor of Computer Science – Software Engineering Major
Edith Cowan University (ECU)