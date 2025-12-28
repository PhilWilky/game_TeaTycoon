# 🎯 PRIORITY ACTION PLAN

## Phase 1: Fix Critical Bugs ✅ COMPLETE

- ✅ Task 1.1: Milk GUI update (`stock_management.gd` line 269)
- ✅ Task 1.2: Cost tracking in `stats_manager.gd` (restock/milk/spoilage methods)
- ✅ Task 1.3: Financial reports show cost breakdown (`tea_shop.gd`)
- ✅ Task 1.4: Cumulative stats track costs (`game_state.gd`)
- ✅ Task 1.5: Revenue tracking bug fixed (signal routing)
- ✅ Task 1.5.1: Cap daily customers
- ✅ Task 1.5.2: Randomize customer bunching
- ✅ Task 1.5.3: Add customer cap hooks for future systems

---

## Phase 2: Save System (2-3 hours) 🚧 NEXT

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
- [x] **Phase 1.5**: Customer flow capped & balanced
- [x] **Phase 2**: Save/load fully functional
- [x] **Phase 3**: Files organized, docs updated

---

## 🚦 STATUS

| Phase     | Status      | Started    | Completed  | Notes                     |
| --------- | ----------- | ---------- | ---------- | ------------------------- |
| Phase 1   | ✅ Complete | 27-12-2025 | 27-12-2025 | Revenue tracking working! |
| Phase 1.5 | ✅ Complete | 27-12-2025 | 27-12-2025 | Customer flow balanced    |
| Phase 2   | ✅ Complete | 28-12-2025 | 28-12-2025 | Save/load fully working!  |
| Phase 3   | ✅ Complete | 28-12-2025 | 28-12-2025 | Files cleaned up          |

✅ Complete  
🟡 In Progress  
⬜ Not Started

---

## 📝 NOTES

_Add issues, decisions, and questions as they come up_
