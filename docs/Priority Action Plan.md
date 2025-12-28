# 🎯 PRIORITY ACTION PLAN

## Phase 1: Fix Critical Bugs ✅ COMPLETE

- ✅ Task 1.1: Milk GUI update (`stock_management.gd` line 269)
- ✅ Task 1.2: Cost tracking in `stats_manager.gd` (restock/milk/spoilage methods)
- ✅ Task 1.3: Financial reports show cost breakdown (`tea_shop.gd`)
- ✅ Task 1.4: Cumulative stats track costs (`game_state.gd`)
- ✅ Task 1.5: Revenue tracking bug fixed (signal routing)

---

## Phase 1.5: Customer Flow & Balance (1 hour) 🚧 NEXT

### Task 1.5.1: Cap daily customers

- **File**: `customer_manager.gd`
- Add `max_customers_per_day: int = 60`
- Add `customers_spawned_today: int` counter
- Stop spawning at max, reset in `_on_day_started()`

### Task 1.5.2: Randomize customer bunching

- Create spawn "waves" (high/low activity periods)
- Random intervals between waves
- Enables turn-skipping for testing

### Task 1.5.3: Add customer cap hooks for future systems

- `max_customers_per_day` as base value (default: 60)
- **Hook for future**: Marketing/staff/equipment upgrades can modify this
- No actual upgrade system yet - just the variable infrastructure

---

## Phase 2: Save System (2-3 hours)

### Setup (Editor)

1. Project Settings → Autoload → Add `scripts/save_system.gd` as `SaveSystem`

### Expand save data (`save_system.gd`)

**Add to `save_data` dictionary:**

- `unlocked_teas`, `tea_inventory`, `milk_stock`
- `cumulative_stats`, `historical_stats`
- `save_timestamp`, `save_version`

**Update `load_game()`:**

- Restore all new fields
- Handle missing fields gracefully (backwards compatibility)

### Auto-save hook (`tea_shop.gd`)

```gdscript
PhaseManager.Phase.MORNING_PREP:
    if GameState.current_day > 1:
        SaveSystem.save_game()
```

### Test cycle

1. Play 1-2 days → Quit → Load
2. Verify: day, money, inventory, milk, stats, unlocked teas

---

## Phase 3: Cleanup (30 minutes)

### File organization

- Delete `scenes/customer_manager.gd` if exists (duplicate)
- Verify no broken references

### Documentation

- Update `Planning & Architecture Guide.md`: date, version "1.0-alpha"
- Regenerate `project-structure.md`

---

## 📋 CHECKLIST

- [x] **Phase 1**: All critical bugs fixed + revenue tracking
- [ ] **Phase 1.5**: Customer flow capped & balanced
- [ ] **Phase 2**: Save/load fully functional
- [ ] **Phase 3**: Files organized, docs updated

---

## 🚦 STATUS

| Phase     | Status         | Started    | Notes                     |
| --------- | -------------- | ---------- | ------------------------- |
| Phase 1   | ✅ Complete    | 27-12-2024 | Revenue tracking working! |
| Phase 1.5 | 🟡 In Progress |            |                           |
| Phase 2   | ⬜ Not Started |            |                           |
| Phase 3   | ⬜ Not Started |            |                           |

---

## 📝 NOTES

_Add issues, decisions, and questions as they come up_
