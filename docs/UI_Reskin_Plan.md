# 🎨 UI Reskin Plan - Tea Tycoon Vintage Aesthetic

**Goal:** Transform the current placeholder UI into a beautiful vintage tea shop interface matching the mockup design.

**Approach:** Hybrid - using image assets for decorative elements + Godot theming for flexibility

**Budget:** Open to purchasing assets or commissioning work on Fiverr

---

## 🧩 CORE CONCEPT: The 5 Reusable Components

**Critical Understanding:** The mockup is NOT an asset to slice up - it's a blueprint showing how 5 core pieces combine.

Think **LEGO blocks, not wallpaper.**

### The 5 Components That Build Everything:

**1. Ornate Panel Frame (9-patch)** ⭐ MOST IMPORTANT

- What: Decorative border with corners and edges
- Used for: All panels, cards, sections
- Format: 9-patch/9-slice (scales without distorting)
- Files needed: 4 corners + 4 edges + center

**2. Header Strip/Banner (9-patch)**

- What: Decorative plaque for titles
- Used for: "Inventory Management", section headers, card titles
- Format: Horizontal 9-slice
- Files needed: Left cap + center + right cap

**3. Buttons (3 states)**

- What: Clickable buttons in vintage style
- Used for: Restock, Buy, +/-, all actions
- Format: Normal, Hover, Pressed states
- Files needed: 3 images per button size

**4. Progress Bars**

- What: Visual fill bars
- Used for: Stock levels, milk freshness, time indicator
- Format: Background + fill graphics
- Files needed: Empty bar + fill bar + optional caps

**5. Background Texture (tileable)**

- What: Parchment/paper behind everything
- Used for: Main background
- Format: Seamless tileable texture
- Files needed: Single tileable image

**Key Point:** Everything in the mockup is built from these 5 things reused and recolored.

### The Two-Phase Build Process:

**Phase A: Structure (Ugly But Works)**

- Build layout using plain Godot containers
- Get positioning, sizing, hierarchy correct
- Ignore visual appearance completely
- Test that it functions properly

**Phase B: Skin (Make It Pretty)**

- Apply Theme with the 5 components
- Layout doesn't change - only appearance
- This is where the magic happens

**Why This Works:**

- Separates layout logic from visual design
- Makes changes easy (change theme, not code)
- Scales properly at all resolutions
- Reuses assets efficiently

---

## 📋 CURRENT STATE vs TARGET

### Current Issues

- ❌ Plain gray boxes with no personality
- ❌ Generic Godot default theme
- ❌ No visual cohesion or branding
- ❌ Looks like a prototype, not a polished game

### Target Vision (From Mockup)

- ✅ Vintage/antique tea shop aesthetic
- ✅ Warm parchment/brown color palette
- ✅ Ornate decorative borders and flourishes
- ✅ Custom vintage serif fonts
- ✅ Themed icons (weather, customers, tea)
- ✅ Wood and parchment textures
- ✅ Hand-drawn/illustrated feel

---

## 🎯 PHASE 1: Asset Sourcing & Preparation

### Required Assets Checklist

#### **Textures & Backgrounds**

- [ ] Parchment/paper texture (main background)
- [ ] Wood panel texture (for UI panels)
- [ ] Dark wood texture (for buttons/headers)
- [ ] Subtle fabric/linen texture (optional for variety)

#### **UI Frames & Borders**

- [ ] Ornate corner decorations (top-left, top-right, bottom-left, bottom-right)
- [ ] Border edges (top, bottom, left, right) for 9-patch scaling
- [ ] Panel frames (large decorative frames for main sections)
- [ ] Small frames (for individual elements like tea cards)

#### **Buttons**

- [ ] Large button (green "RESTOCK" style) - normal, hover, pressed states
- [ ] Medium button (inventory tabs) - normal, hover, pressed states
- [ ] Small button (+ / - buttons) - normal, hover, pressed states
- [ ] Tab buttons (Menu, Inventory, Staff, Reports) - active/inactive states

#### **Progress Bars**

- [ ] Horizontal bar background (empty state)
- [ ] Horizontal bar fill (for tea stock, milk stock)
- [ ] Bar decorative caps (left and right ends)
- [ ] Phase indicator bar (Quiet/Rush/Final sections with different colors)

#### **Icons & Sprites**

- [ ] Weather icons (sunny ☀️, rainy 🌧️, cold ❄️, hot 🔥)
- [ ] Tea cup icon (for day counter)
- [ ] Money/coin icon
- [ ] Customer character heads (5 variations: happy, neutral, angry, etc.)
- [ ] Tea pot/tea bag icon
- [ ] Milk bottle/crate icon
- [ ] Clock/timer icon

#### **Fonts**

- [ ] Header font (vintage serif - like in mockup)
- [ ] Body text font (readable serif or sans-serif)
- [ ] Number font (clear, easy to read for money/stats)

---

## 🛒 WHERE TO GET ASSETS

### Option A: Asset Packs (Recommended for Speed)

**Itch.io:**

- Search: "vintage UI", "medieval UI", "fantasy UI", "tavern UI"
- Price range: $5-$20 typically
- Examples to look for:
  - Vintage/Steampunk UI packs
  - Medieval fantasy UI kits
  - Café/Restaurant themed UI

**Unity Asset Store / Unreal Marketplace:**

- Many assets work in Godot (just need the PNG/sprite files)
- Search same terms as above
- Often higher quality but pricier ($15-$50)

**GameDev Market / Kenney.nl:**

- Kenney has free UI packs (might need recoloring)
- GameDev Market has premium options

### Option B: Commission Custom Assets (Fiverr)

**What to Request:**

- "Vintage tea shop UI kit for game"
- "Victorian/Edwardian style game UI elements"
- Provide your mockup as reference

**Budget Estimate:**

- Basic UI pack: $50-$150
- Full custom set matching mockup: $200-$500
- Individual elements: $5-$20 each

**Recommended Fiverr Search Terms:**

- "game UI design vintage"
- "pixel art UI" (if you want pixel art style)
- "2D game assets UI"

### Option C: Free Resources + DIY

**Fonts (Free):**

- Google Fonts: "IM Fell English", "Crimson Text", "Libre Baskerville"
- DaFont: Search "vintage", "victorian", "old english"

**Textures (Free):**

- Textures.com (some free)
- OpenGameArt.org
- Freepik (with attribution)

**Create Your Own:**

- Use GIMP/Photoshop to create textures
- Use public domain Victorian ornaments
- Combine free elements into custom designs

---

## 🔧 PHASE 2: Godot Theme Setup

### Task 2.1: Create Base Theme Resource

**File:** `themes/tea_shop_vintage_theme.tres`

**What to Set Up:**

1. Create new Theme resource in Godot
2. Import all fonts
3. Create StyleBoxTexture for each UI element type
4. Set up color palette

**Color Palette (from mockup):**

```
Parchment Background: #F4E8D0
Dark Brown (wood): #3D2817
Medium Brown: #6B4423
Light Brown (borders): #8B6F47
Green (buttons): #4A7C4E
Red (alerts): #A84448
Gold (accent): #D4A574
```

### Task 2.2: Configure StyleBox Elements

**Panel StyleBox:**

- Background: Parchment texture
- Border: Wood frame using 9-patch
- Corner decorations as overlays

**Button StyleBox (3 states):**

- Normal: Dark wood texture, subtle shadow
- Hover: Slightly lighter, border glow
- Pressed: Darker, inset effect

**Label StyleBox:**

- Background: Transparent or subtle parchment
- Fonts: Apply vintage fonts
- Colors: Dark brown for good contrast

### Task 2.3: Create Custom Components

**Components to Build:**

1. **VintagePanel** (Panel with ornate borders)
2. **VintageButton** (Styled button with hover effects)
3. **VintageProgressBar** (Custom progress bar with decorative caps)
4. **VintageTabContainer** (Themed tabs)
5. **CustomerQueueSlot** (Character portrait frame)

---

## 🎨 PHASE 3: UI Layout Redesign

### Task 3.1: Main Game Screen Layout

**Current Structure to Update:**

```
TeaShop.tscn
├── TopBar (Day, Money, Reputation, Weather, Phase Progress)
├── AlertPanel (Weather message)
├── TabContainer
│   ├── Menu (Tea cards)
│   ├── Inventory (Stock management)
│   ├── Staff (Future)
│   └── Reports (End of day)
├── ActionButtons (Start Day, Save Game)
└── CustomerQueue
```

**New Structure with Vintage Elements:**

```
TeaShop.tscn (with vintage background)
├── DecorativeFrame (top ornament)
├── TopBar
│   ├── BackgroundPanel (wood texture)
│   ├── DayDisplay (with teacup icon)
│   ├── MoneyDisplay (with coin icon)
│   ├── ReputationDisplay (stars/rating visual)
│   ├── WeatherIcon (animated icon)
│   └── PhaseProgress (vintage progress bar)
├── WeatherAlert (parchment banner)
├── TabContainer (vintage tab design)
│   ├── Menu (Tea cards with decorative frames)
│   ├── Inventory (Wooden panel aesthetic)
│   ├── Staff (Placeholder)
│   └── Reports (Scroll/parchment style)
├── ActionButtons (Large vintage buttons)
├── CustomerQueue (Character portraits in frames)
└── DecorativeFrame (bottom ornament)
```

### Task 3.2: Inventory Panel Redesign

**Match Mockup Layout:**

- Left section: Tea stock with decorative frame
  - Tea icon + name
  - Cost display
  - Visual stock bar (not just numbers)
  - Restock controls (- 0 + buttons)
  - Large "RESTOCK" button
- Right section: Milk stock with decorative frame

  - Milk icon
  - Visual stock bar
  - Alert banner if low
  - "Buy Crate" button

- Bottom section: Today's Trade
  - Phase indicator (Quiet/Rush/Final)
  - Customer count
  - Customer queue with character portraits

### Task 3.3: Tea Cards Redesign

**Current:** Plain rectangles with text

**Target:**

- Ornate card frame
- Tea icon at top
- Name in vintage font
- Stats displayed with icons
- Price in decorative box
- "Locked" state with vintage lock icon
- Hover effect (slight glow/lift)

---

## 🚀 PHASE 4: Polish & Effects

### Task 4.1: Animations & Transitions

- [ ] Fade in/out for phase changes
- [ ] Button press animations
- [ ] Tab switch transitions
- [ ] Customer queue animations (slide in/out)
- [ ] Money counter roll-up effect
- [ ] Stock bar fill animations

### Task 4.2: Audio Feedback (Future)

- [ ] Button click sounds (wood/paper sounds)
- [ ] Customer arrival sounds
- [ ] Tea pouring sounds
- [ ] Cash register ding for sales
- [ ] Ambient tea shop background music

### Task 4.3: Particle Effects

- [ ] Steam particles from tea cups
- [ ] Coin sparkles for money earned
- [ ] Weather effects (rain, snow, sun rays)
- [ ] Customer satisfaction hearts/stars

---

## 📐 IMPLEMENTATION PRIORITIES

### High Priority (Must Have)

1. ✅ Basic parchment background
2. ✅ Vintage fonts
3. ✅ Decorative panel frames
4. ✅ Styled buttons
5. ✅ Custom progress bars
6. ✅ Customer portraits in queue

### Medium Priority (Should Have)

7. ⏸️ Ornate corner decorations
8. ⏸️ Wood textures for panels
9. ⏸️ Weather icons
10. ⏸️ Tab styling
11. ⏸️ Icon set (tea, milk, money)

### Low Priority (Nice to Have)

12. ⬜ Hover effects on cards
13. ⬜ Smooth transitions
14. ⬜ Particle effects
15. ⬜ Advanced animations
16. ⬜ Audio feedback

---

## 📊 PROGRESS TRACKING

| Phase | Task                       | Status         | Time Est. | Notes               |
| ----- | -------------------------- | -------------- | --------- | ------------------- |
| 1     | Find/buy asset pack        | ⬜ Not Started | 2-4 hrs   | Research & purchase |
| 1     | Download & organize assets | ⬜ Not Started | 1 hr      | File organization   |
| 2     | Create theme resource      | ⬜ Not Started | 2 hrs     | Base setup          |
| 2     | Import fonts               | ⬜ Not Started | 30 min    | Test readability    |
| 2     | Configure StyleBoxes       | ⬜ Not Started | 3 hrs     | Per UI element      |
| 3     | Redesign main layout       | ⬜ Not Started | 4 hrs     | Scene restructure   |
| 3     | Inventory panel reskin     | ⬜ Not Started | 3 hrs     | Match mockup        |
| 3     | Tea cards redesign         | ⬜ Not Started | 2 hrs     | Per card type       |
| 4     | Add animations             | ⬜ Not Started | 2 hrs     | Polish              |
| 4     | Test & refine              | ⬜ Not Started | 2 hrs     | Bug fixes           |

**Total Estimated Time:** 20-25 hours

---

## 🎓 LEARNING RESOURCES

### Godot UI Theming Tutorials

- **Official Docs:** https://docs.godot.com/en/stable/tutorials/ui/gui_using_theme_editor.html
- **GDQuest:** UI theming videos on YouTube
- **HeartBeast:** Godot UI tutorials

### 9-Patch Sprites

- **Tutorial:** How to create scalable UI panels
- **Tool:** Use Godot's built-in 9-patch editor
- **Reference:** https://docs.godot.com/en/stable/tutorials/2d/using_tilemaps.html

### Asset Integration

- **Import Settings:** Ensure "Filter" is OFF for pixel art, ON for smooth assets
- **Compression:** Use "Lossless" for UI elements
- **Mipmaps:** Generally OFF for UI

---

## 💡 TIPS & BEST PRACTICES

### Asset Organization

```
themes/
├── tea_shop_vintage_theme.tres (main theme)
├── fonts/
│   ├── headers.ttf
│   ├── body.ttf
│   └── numbers.ttf
├── textures/
│   ├── parchment_bg.png
│   ├── wood_panel.png
│   └── fabric.png
├── borders/
│   ├── corner_tl.png
│   ├── corner_tr.png
│   ├── edge_top.png
│   └── frame_large.png
├── buttons/
│   ├── button_large_normal.png
│   ├── button_large_hover.png
│   └── button_large_pressed.png
├── icons/
│   ├── weather_sunny.png
│   ├── tea_cup.png
│   └── customer_happy.png
└── progress_bars/
    ├── bar_bg.png
    ├── bar_fill.png
    └── bar_cap.png
```

### Performance Considerations

- Keep texture sizes reasonable (max 2048x2048 for backgrounds)
- Use texture atlases for small icons
- Compress textures appropriately
- Test on lower-end hardware

### Consistency Checklist

- [ ] All buttons use same style
- [ ] Consistent spacing/margins (use constants)
- [ ] Color palette adhered to throughout
- [ ] Font sizes hierarchical (headers > body > small)
- [ ] Border widths consistent
- [ ] Icon sizes standardized

---

## 🎯 NEXT STEPS

### Immediate Actions (This Session)

1. ⬜ Delete old `Priority Action Plan.md`
2. ⬜ Research asset packs (spend 30 min browsing itch.io)
3. ⬜ Bookmark 3-5 potential asset packs
4. ⬜ Decide: buy pack vs commission vs DIY

### Short Term (This Week)

1. ⬜ Purchase/download chosen asset pack
2. ⬜ Import assets into Godot project
3. ⬜ Create base theme resource
4. ⬜ Test one UI element (e.g., a button) with new theme

### Medium Term (Next 2 Weeks)

1. ⬜ Complete Phase 2 (theme setup)
2. ⬜ Start Phase 3 (layout redesign)
3. ⬜ Get inventory panel matching mockup

### Long Term (Next Month)

1. ⬜ Complete all high priority items
2. ⬜ Add medium priority polish
3. ⬜ Playtest with new UI
4. ⬜ Iterate based on feedback

---

## 📝 NOTES & IDEAS

### Design Decisions to Make

- [ ] Exact vintage era? (Victorian, Edwardian, 1920s, etc.)
- [ ] Pixel art vs hand-drawn vs realistic textures?
- [ ] Color vs sepia/muted tones?
- [ ] How "busy" should decorations be?

### Future Enhancements

- Seasonal themes (Christmas tea shop, summer garden, etc.)
- Unlockable UI skins
- Day/night mode variations
- Accessibility: high contrast mode

### Questions to Answer

- Should we animate the tea cup icon?
- Do customer portraits need multiple emotions?
- How to handle very long tea names in cards?
- Mobile compatibility needed?

---

## ✅ SUCCESS CRITERIA

The UI reskin will be considered complete when:

- [ ] All game screens use the vintage theme
- [ ] Mockup aesthetic is faithfully recreated
- [ ] UI is clear and readable
- [ ] No placeholder gray boxes remain
- [ ] Theme is consistent across all elements
- [ ] Performance is not negatively impacted
- [ ] Players identify it as a "tea shop game" immediately

---

**Version:** 1.0  
**Last Updated:** 28-12-2025  
**Status:** Planning Phase
