# Tea Shop Tycoon – File Map & Flow (Merged, Mermaid-Compatible)

This replaces the ASCII diagram with **Mermaid** diagrams (strict-compatible) and explicitly includes **TeaShop.tscn**. A plain text outline is included as a fallback.

---

## Directory Overview

- **project.godot / icon.svg / themes/** – Project settings, app icon, global theme
- **docs/** – Design & usage guides
- **scenes/** – Packed scene prefabs (UI and game views)
- **scripts/** – Core gameplay scripts
  - **scripts/systems/** – Game systems & managers (non-UI)
  - **scripts/ui/** – UI logic (HUD, panels, widgets)

---

## Scenes (`scenes/`)

- **TeaShop.tscn** — Root gameplay scene; hosts key managers & UI nodes
- **customer_queue.tscn** — Visual queue; spawns/positions customers
- **game_hud.tscn** — Top-level HUD: money/stock/reputation/time
- **inventory_panel.tscn** — Morning prep inventory UI
- **phase_panel.tscn** — Phase/status UI + controls
- **staff_card.tscn** — Staff listing card (future staff system)
- **tea_card.tscn** — Tea listing/selection card

---

## Core Scripts (`scripts/`)

- **game_state.gd** — Canonical runtime state (cash, day, phase, unlocks, stock, rep, RNG seed). Ideal Save/Load owner
- **game_types.gd** — Enums/structs/type aliases (phases, tea ids, event payloads)
- **events.gd** — Central signal bus (pub/sub for systems & UI)
- **game_loop_manager.gd** — Orchestrates phases; owns timers & transitions
- **game_logic.gd** — High-level rules/coordinator (connects managers; applies outcomes)
- **stats_manager.gd** — Session + lifetime stats aggregation for reports/achievements

### Systems (`scripts/systems/`)

- **phase_manager.gd** — Phase state machine helpers (enter/exit hooks)
- **customer_demand.gd** — Demand model (base + weather + pricing + synergy)
- **customer_manager.gd** — Spawning, queueing, service resolution, satisfaction
- **inventory_system.gd** — Tea stock, capacities, pricing; purchase in Morning
- **tea_manager.gd** — Tea definitions, unlock gates, prices (→ soon from JSON)
- **tea_production_manager.gd** — Brew/produce cadence & yields
- **milk_system.gd** — Daily spoilage, purchase, availability checks
- **stock_management.gd** — Cross-cutting stock helpers

### UI (`scripts/ui/`)

- **game_hud.gd** — Subscribes to state/events; renders HUD
- **phase_panel.gd** — Shows current phase; controls next/skip
- **customer_queue.gd** — Visual queue; binds to customer_manager
- **tab_notification_system.gd** — Adds/removes tab badges (•, ⚠, ✉)

### Widget scripts

- **staff_card.gd** — Binds staff data to card (role, wage, actions)
- **tea_card.gd** — Binds tea data to card (price, unlock state)

---

## Component Map (Mermaid – strict compatible)

```mermaid
graph TD
  A["TeaShop.tscn root"]
  B["game_loop_manager.gd"]
  C["game_state.gd"]
  D["events.gd"]
  E["game_hud.tscn + ui/game_hud.gd"]
  F["phase_panel.tscn + ui/phase_panel.gd"]
  G["inventory_panel.tscn + ui all"]
  H["customer_queue.tscn + ui/customer_queue.gd"]
  I["systems/phase_manager.gd"]
  J["game_logic.gd"]
  K["stats_manager.gd"]
  L["systems/customer_manager.gd"]
  M["systems/inventory_system.gd"]
  N["milk_system.gd"]
  O["tea_manager.gd"]
  P["systems/customer_demand.gd"]

  A --> B
  A --> C
  A --> D
  A --> E
  A --> F
  A --> G
  A --> H

  B --> I
  B --> J
  B --> K

  J --> L
  J --> M
  J --> N
  J --> O
  J --> P

  L --- H
  L --- D
  M --- D
  N --- D
  O --- D
  P --- D
  I --- D
  K --- D
  E --- D
  F --- D
  G --- D
```

### Fallback (Plain Text)

- TeaShop.tscn root
  - game_loop_manager.gd
    - systems/phase_manager.gd
    - game_logic.gd
      - systems/customer_manager.gd ↔ customer_queue.tscn
      - systems/inventory_system.gd
      - milk_system.gd
      - tea_manager.gd
      - systems/customer_demand.gd
    - stats_manager.gd
  - game_state.gd
  - events.gd (signal bus)
  - game_hud.tscn + ui/game_hud.gd
  - phase_panel.tscn + ui/phase_panel.gd
  - inventory_panel.tscn + ui/\*
  - customer_queue.tscn + ui/customer_queue.gd
- All UI and systems publish/subscribe via events.gd

---

## Runtime Flow (One Day Cycle)

```mermaid
sequenceDiagram
  participant P as Player
  participant T as TeaShop.tscn
  participant L as game_loop_manager
  participant PH as phase_manager
  participant INV as inventory_system
  participant TEA as tea_manager
  participant MIL as milk_system
  participant C as customer_manager
  participant D as customer_demand
  participant H as game_hud
  participant S as stats_manager
  participant BUS as events

  T->>L: start_game
  L->>PH: enter Morning
  BUS-->>H: phase_changed Morning
  P->>INV: purchase stock via UI
  INV-->>BUS: inventory_updated, cash_changed

  L->>PH: enter Day
  BUS-->>H: phase_changed Day
  C->>D: demand_modifiers
  C->>INV: request_serve
  INV->>MIL: check_spoilage
  INV-->>C: serve_result
  C-->>BUS: customer events
  BUS-->>H: update HUD

  L->>PH: enter Evening
  BUS-->>H: phase_changed Evening
  S->>BUS: day_summary_ready
  Note over T,L: Auto-save at end of Evening
```

---

## Signals & Responsibilities

- **events.gd** (bus):

  - `phase_changed(phase)`
  - `inventory_updated(stock)` / `cash_changed(amount)`
  - `customer_joined(data)` / `customer_served(result)` / `queue_updated(n)`
  - `tea_unlocked(id)` / `reputation_changed(value)`
  - `day_summary_ready(report)`

- **game_loop_manager.gd** → Emits `phase_changed`, advances time
- **customer_manager.gd** → Spawns customers, resolves service, emits satisfaction
- **inventory_system.gd / milk_system.gd** → Manage stock/spoilage, emit updates
- **UI (HUD, panels)** → Listen only; render + send user intent

---
