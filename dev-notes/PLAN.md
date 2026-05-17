# Project Survivor Development Plan

Last updated: May 17, 2026

## Project Overview

**Genre:** Fast-action dungeon roguelike inspired by Vampire Survivors.

**Engine/Runtime:** Custom C/C++ stack (`survivor_core` + `survivor_platform`) with BGFX rendering and miniaudio audio (planned).

**Core Pillars:**
- Entity-Component System (ECS) for ability and entity management
- Data-driven ability definitions (YAML/JSON)
- Fast-paced, deterministic gameplay mechanics
- Cross-platform support (Linux, Windows, macOS, iOS, Android)
- Controller support for console-like experience
- Steam integration (stretch goal)

---

## Current Status: Phase 1 ✓ COMPLETE

### Infrastructure Baseline (COMPLETE)

**Deliverables:**
- ✓ CMake build system (3.21+, Ninja generator)
- ✓ Debug and Release presets (both compile without warnings)
- ✓ C17 core simulation layer (`survivor_core` static library)
- ✓ C++20 platform layer (`survivor_platform` static library)
- ✓ Basic ECS framework (entity storage, component registration, queries)
- ✓ Ability system scaffolding (registry, component types, definitions)
- ✓ Greyscale/desaturation post-process effect (ported from project-crown)
- ✓ Code formatting (`clang-format` + `.editorconfig`)
- ✓ AGENTS.md coding standards document
- ✓ Doxygen documentation configuration
- ✓ Build scripts (`dev.sh`, `release.sh`, `fps-release.sh`, `asan.sh`, `profile.sh`, `tests.sh`, `docs.sh`)
- ✓ CTest framework with basic tests
- ✓ GitHub repository created (public, main branch)
- ✓ Comprehensive README.md

**Completed Tasks:**
1. infrastructure-copy ✓
2. cmake-setup ✓
3. clang-format-setup ✓
4. doxyfile-create ✓
5. agents-md-create ✓
6. texture-designer-copy ✓ (greyscale effect ported)
7. greyscale-port ✓
8. basic-src-stub ✓
9. third-party-setup ✓ (planned deps documented)
10. initial-compile ✓
11. git-init ✓
12. github-repo-create ✓
13. initial-push ✓

**Metrics:**
- Compilation time (clean debug): ~2 seconds
- Compilation time (clean release): ~2 seconds
- Executable size (debug): 31 KB
- Executable size (release): TBD
- Test suite: 1 test, 100% pass rate

---

## Phase 2: UI and Core Gameplay (IN PROGRESS)

### Objective

Create visible UI screens (splash, title, character select) and establish screen/scene management framework. Integrate ImGui (non-docking). Validate ECS with real gameplay components.

### Planned Deliverables

1. **Screen Manager** — State machine for transitions (Splash → Title → CharSelect → Gameplay, etc.)
2. **Splash Screen** — Centered static image
3. **Title Screen** — ImGui buttons (Play, Options, Quit)
4. **Character Select Screen** — Placeholder character slots
5. **ImGui Integration** — Full Dear ImGui layer (non-docking branch)
6. **Basic Components** — Position, Velocity, Sprite (for gameplay testing)
7. **Input Handling** — Keyboard + mouse (for now)

### Tasks

- [ ] screen-manager — Implement screen/state manager system
- [ ] splash-screen — Implement splash screen (centered image, static)
- [ ] title-screen — Implement title screen (ImGui buttons, fixed layout)
- [ ] char-select-screen — Implement character select screen stub (ImGui, fixed)
- [ ] basic-components — Create basic game components (Position, Velocity, Sprite)
- [ ] input-system — Implement input polling and mapping
- [ ] imgui-integration — Full ImGui initialization and render pass

### Definition of Done

- All UI screens visible and navigable
- Screen transitions smooth (no crashes or hangs)
- ImGui renders correctly with no errors
- At least 5 unit tests covering screen transitions
- Code compiles without warnings (debug + release)
- Documented in code comments

### Immediate Next Tasks

1. Implement `ScreenManager` class with state machine
2. Create abstract `Screen` base class
3. Implement `SplashScreen` (draw centered image)
4. Implement `TitleScreen` (ImGui buttons)
5. Implement `CharSelectScreen` (placeholder)

---

## Phase 3: ECS and Ability System (PLANNED)

### Objective

Flesh out the ECS with real gameplay data. Implement ability loading and execution framework. Validate deterministic ability behavior.

### Planned Deliverables

1. **ECS Enhancement** — Query systems, bulk operations, component iteration
2. **Ability Schema** — YAML/JSON format for ability definitions
3. **Ability Loader** — Parse YAML/JSON and populate registry
4. **Ability Execution** — Basic ability spawning and update
5. **System Framework** — Explicit system ordering and scheduling
6. **Determinism Tests** — Seed-based replay validation

### Ability Schema (Draft YAML Format)

```yaml
abilities:
  - id: "fireball"
    name: "Fireball"
    description: "Launches a fireball projectile"
    base_damage: 25.0
    cooldown: 1.5
    duration: 2.0
    movement: linear
    movement_speed: 100.0
    hitbox_type: circle
    hitbox_radius: 16.0
    asset_sprite: "effects/fireball"
    knockback: 5.0
    status_effects: []

  - id: "ice_spike"
    name: "Ice Spike"
    description: "Summons ice spikes around caster"
    base_damage: 15.0
    cooldown: 2.0
    duration: 1.0
    movement: none
    hitbox_type: circle
    hitbox_radius: 20.0
    asset_sprite: "effects/ice_spike"
    knockback: 0.0
    slowdown_factor: 0.5
    slowdown_duration: 2.0
```

### Tasks

- [ ] ecs-framework — Finalize ECS query and iteration APIs
- [ ] ability-schema — Design and document YAML/JSON schema
- [ ] ability-loader — Implement YAML parser (use yaml-cpp or similar)
- [ ] ability-executor — Execute abilities, spawn projectiles, handle collisions (stub)
- [ ] ecs-systems — Implement movement, ability expiry, cleanup systems
- [ ] determinism-tests — Seed-based replay tests

### Definition of Done

- At least 10 abilities loadable from YAML files
- Abilities can be spawned and updated in main loop
- Determinism verified: same seed = same execution path
- Performance: ability processing <2ms per frame (100 active abilities)

---

## Phase 4: Cross-Platform Foundation (PLANNED)

### Objective

Research and design cross-platform build infrastructure. Abstract graphics, input, and audio for multiple targets.

### Planned Deliverables

1. **Build Matrix** — Debug CMake configuration for Android, iOS, Windows, macOS
2. **Graphics Abstraction** — BGFX backend selection (OpenGL ES, Metal, Direct3D, Vulkan)
3. **Input Abstraction** — Touch, keyboard, controller unification
4. **Audio Backend** — miniaudio integration
5. **CI/CD Pipeline** — GitHub Actions for multi-platform builds

### Build Targets

- [x] Linux (reference platform) ✓
- [ ] Windows (x86-64)
- [ ] macOS (Intel + Apple Silicon)
- [ ] iOS (iPad + iPhone)
- [ ] Android (ARM + x86-64)

### Key Challenges

1. **Android NDK build integration** — CMake cross-compilation
2. **iOS / macOS code signing** — XCode integration
3. **Graphics API selection** — Runtime or compile-time?
4. **Controller mapping** — SDL2 vs platform-native APIs
5. **Asset bundling** — Compressed vs streaming

### Tasks

- [ ] crown-crosscompile-review — Analyze project-crown's multi-platform approach
- [ ] graphics-abstraction — Design renderer backend selection
- [ ] input-abstraction — Design input layer for touch/controller
- [ ] android-cmake — Set up Android NDK CMake toolchain
- [ ] ios-cmake — Set up iOS CMake toolchain
- [ ] ci-setup — Configure GitHub Actions for multi-platform builds

---

## Phase 5: Game Content (PLANNED)

### Objective

Implement core gameplay loop: player movement, ability activation, enemy spawning, combat.

### Planned Deliverables

1. **Player Controller** — Keyboard/controller input, movement, ability hotkeys
2. **Enemy Archetypes** — 3-5 basic enemy types with different behaviors
3. **Ability Diversity** — 15-20 distinct abilities with varied mechanics
4. **Level Generation** — Procedural room/arena generation
5. **Combat System** — Damage calculation, status effects, knockback
6. **Progression** — Character leveling, stat upgrades, item drops

### Gameplay Loop

```
[Splash] → [Title] → [CharSelect] → [Play]
                                       ↓
                    [Enemy spawn] → [Combat] → [Victory/Defeat]
                           ↑                          ↓
                           └──────────────────────────┘
```

---

## Phase 6: Polish & Release (PLANNED)

### Objective

Performance optimization, asset finalization, accessibility, and platform-specific polish.

### Planned Deliverables

1. **Performance Budget** — 60 FPS on reference hardware
2. **Asset Pipeline** — Sprite sheets, animations, audio compression
3. **UI Polish** — Smooth transitions, visual feedback
4. **Accessibility** — Colorblind modes, high contrast, controller remapping
5. **Platform Builds** — Signed/notarized releases for all targets
6. **Steam Integration** (stretch) — Achievements, cloud saves, overlay

---

## Technical Architecture

### Module Structure

```
include/survivor/
  core/                   # Deterministic simulation API
    ecs.h
    ability_system.h
    math_utils.h
  platform/               # C++ platform interfaces
    renderer.hpp
    input.hpp
    audio.hpp

src/
  core/                   # C17 simulation
    ecs.c
    ability_system.c
    math_utils.c
  platform/               # C++20 platform shell
    app.cpp
    renderer.cpp
    ui_layer.cpp
    screen_manager.cpp
    texture_manager.cpp
    greyscale_effect.cpp
  main.cpp

tests/
  test_ecs.c              # Unit tests
  CMakeLists.txt

assets/
  abilities/              # YAML/JSON ability definitions
  sprites/                # Sprite sheets and assets
  audio/                  # Music and SFX
```

### Invariants

1. **Determinism:** Core simulation produces identical results given same seed + input
2. **Platform Independence:** No platform/graphics knowledge in `src/core/`
3. **Performance:** Update <5ms/frame, render <10ms/frame (1080p)
4. **Memory:** Reasonable allocation strategy; no per-frame allocations in hot paths
5. **Thread Safety:** Single-threaded for Phase 1-3; async loading in Phase 4+

---

## Build and Workflow

- **CMake presets:** debug, release, profile, coverage, mutation
- **Test workflow:** `./tests.sh` before all commits
- **Release workflow:** `./release.sh` for packaged binaries
- **Documentation:** `./docs.sh` generates Doxygen HTML
- **Performance:** `./fps-release.sh` for profiling

---

## Known Unknowns & Risks

1. **BGFX + ImGui docking branch compatibility:** User notes special code required. Need to verify non-docking branch has fewer dependencies.
2. **Cross-compilation complexity:** Android/iOS builds may have unforeseen CMake toolchain challenges.
3. **Ability system balance:** No playtesting yet; may need significant iteration.
4. **Art asset pipeline:** Sprite quality and animation requirements unclear.
5. **Steam integration scope:** Stretch goal; feasibility depends on time/resources.

---

## Success Metrics

### Phase 1 ✓
- [x] Compiles without warnings (debug + release)
- [x] GitHub repository active
- [x] ECS framework functional
- [x] Build scripts working

### Phase 2 (In Progress)
- [ ] All UI screens visible and navigable
- [ ] Screen transitions tested
- [ ] ImGui rendering without errors
- [ ] 10+ tests passing

### Phase 3
- [ ] 10+ abilities loadable from YAML
- [ ] Determinism verified
- [ ] Performance targets met

### Phase 4
- [ ] Multi-platform builds created (Windows, macOS, iOS, Android)
- [ ] GitHub Actions CI/CD pipeline operational

### Phase 5
- [ ] Complete gameplay loop playable
- [ ] Enemy variety and ability balance

### Phase 6
- [ ] Performance optimization targets met
- [ ] Releasable builds for all platforms
- [ ] Asset pipeline finalized

---

## Next Steps

1. **This week:** Complete Phase 2 UI screens
2. **Next week:** Implement Phase 3 ability system
3. **Weeks 3-4:** Cross-platform build investigation
4. **Weeks 5+:** Game content and polish phases

---

## Contact & Notes

Built with project-crown infrastructure patterns. See `AGENTS.md` for development guidelines.

GitHub: https://github.com/gardjl-unf/project-survivor
