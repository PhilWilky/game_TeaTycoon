# Tea Shop Tycoon – Gaps, Risks & Quick Wins

## 🚧 Gaps & Risks to Watch

- **Save/Load missing** → Blocks playtesting + balance persistence
- **Config migration** (hard-coded → JSON) → Risk of data drift across systems
- **Balance surface area** grows fast once staff/locations/equipment land
- **Single Source of Truth** not formalized (central DataRegistry/GameState)
- **Coupling risks** between UI and managers (ensure signal-first comms)
- **Versioning** for future save compatibility not defined
- **Testability** (seeded RNG + repro harness) not formalized

---

## ⚡ High-Impact Quick Wins

1. **Save/Load MVP**
   - JSON persistence via `game_state.gd`
   - Include: day/phase, cash, inventory, milk, unlocks, rep, weather seed, stats
2. **Config-first data**
   - Tea, weather, unlocks JSON + DataRegistry loader
3. **Weather × Tea synergy**
   - Config-driven multipliers feeding customer demand
4. **Evening Report deltas**
   - Profit vs. yesterday, stockouts, queue abandonment
5. **Signal hygiene pass**
   - Remove cross-pulling; enforce event-driven updates
6. **Debug overlay**
   - Show seed, day, phase, multipliers, fps
7. **Seeded playtests**
   - Input seed → reproducible sessions

---
