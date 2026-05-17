# Coding Guidelines — Survivor Project

These guidelines apply to **all future code changes** in this repository.
They follow the same patterns established in project-crown and codify standards
that keep the codebase safe, readable, and maintainable.

---

## 1. Language Standards

| Layer | Standard | Target |
|-------|----------|--------|
| Simulation core (`src/core/*.c`) | **C17** | `survivor_core` static lib |
| Platform shell (`src/platform/`) | **C++20** | `survivor_platform` static lib |
| Tests (`tests/`) | C or C++20 (match the code under test) | per-test executables |

Compiler flags: `-Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined`
in Debug builds. Never suppress warnings in project code — only in
third-party translation units when necessary.

---

## 2. Formatting

Formatting is enforced by `.clang-format` (LLVM base, 4-space indent, 120-col
limit) and `.editorconfig`.

- **Indent:** 4 spaces, no tabs.
- **Line endings:** LF.
- **Column limit:** 120.
- **Pointer style:** `int* ptr` (left-aligned).
- **Namespace indentation:** None (contents at column 0).

Run `clang-format -i <file>` on every modified C/C++ file before committing.
Do **not** reformat files that you did not otherwise change in the same commit.

---

## 3. Naming Conventions

| Symbol kind | Convention | Example |
|-------------|-----------|---------|
| Classes, structs, enums, namespaces | PascalCase | `ExampleClass`, `MyNamespace` |
| Functions, member functions | PascalCase | `ThisIsMyFunction()` |
| Local variables, parameters | camelCase | `inputVariable`, `chunkCount` |
| Private member variables | `m_` + PascalCase | `m_MemberVariable` |
| Static variables (TU or class) | `s_` + PascalCase | `s_StaticInt` |
| Source file names | snake_case | `ability_system.c`, `screen_manager.cpp` |
| Header guards | `SURVIVOR_<PATH>_HPP` | `SURVIVOR_PLATFORM_RENDERER_HPP` |
| C-only public API (core) | `survivor_` prefix, snake_case | `survivor_entity_create()` |

---

## 4. Documentation

### Every file must have an `@file` header

```cpp
/**
 * @file my_module.cpp
 * @brief One-line purpose.
 */
```

### Every function must have a Doxygen block

```cpp
/**
 * @brief What it does — one sentence.
 *
 * Extended explanation when the behavior is non-obvious.
 *
 * @param[in]  name   Description.
 * @param[out] result Description.
 * @return Description of return value.
 */
```

### Comment policy

- **Do** comment intent, constraints, boundary semantics, tie-break behavior.
- **Do not** comment what the syntax already says (`i++; // increment i`).
- **Do** annotate every call into a third-party API (bgfx, ImGui, SDL2, etc.)
  explaining *why* it is called and what Survivor expects.

---

## 5. Testing

- **Every functional change** must include or update tests.
- Prefer deterministic fixtures and fixed seeds.
- Test files must have `@file` headers.
- Over-cover before under-covering — integration tests are especially valuable.
- Run the full test suite (`./tests.sh` or `ctest --preset debug`) before
  committing.

**Test layers:**
- Unit tests: isolated module behavior
- Integration tests: cross-module behavior and contracts
- End-to-end scenario tests: startup → runtime interactions → shutdown flow
- Regression tests: fixed bugs must receive a reproducer test
- Performance budget checks: frame/update timing constraints

---

## 6. Error Handling

- The main entry point (`src/main.cpp`) has a top-level `try/catch` block for
  `std::exception`.
- Use `new (std::nothrow)` for allocations where failure is recoverable.
  Always null-check the result and clean up partial state.
- Add dimension/size guards before allocating or resizing buffers based on
  external input (e.g. image files, YAML/JSON asset files).
- Document failure modes in function Doxygen blocks.

---

## 7. Architecture Boundaries

```
include/survivor/      — public C headers (simulation API)
include/survivor/platform/ — C++ platform interfaces

src/core/*.c           — C17 simulation core (no C++ / no platform deps)
  ecs.c                — entity-component system storage
  ability_system.c     — ability loading, component management
  math_utils.c         — utility math functions

src/platform/          — C++20 platform shell
  app.cpp              — main application state
  renderer.cpp         — BGFX rendering interface
  ui_layer.cpp         — ImGui integration
  screen_manager.cpp   — scene/screen state management
  texture_manager.cpp  — texture loading and caching
  greyscale_effect.cpp — greyscale desaturation post-process

tests/                 — per-module C and C++ test executables
```

- The C core must **never** include C++ headers or depend on platform code.
- Platform code may call C core APIs via `extern "C"` headers.
- Keep subsystem boundaries clean: rendering code must not know about ability
  logic; ability logic must not know about rendering.

---

## 8. Development Workflow

For every functional change:

1. Update or add tests.
2. Update documentation (function docs, file headers, plan notes if applicable).
3. Run `clang-format -i` on modified files.
4. Run the full test suite (`./tests.sh` or `ctest --preset debug`).
5. Build with sanitizers enabled (default in Debug preset).

---

## 9. GitHub Branch, PR, and Merge Workflow

### Branching

- Do not implement features directly on `main`.
- Create a branch per task:
  - `feat/<area>-<short-name>`
  - `fix/<area>-<short-name>`
  - `refactor/<area>-<short-name>`
  - `test/<area>-<short-name>`
  - `docs/<area>-<short-name>`

### Commit policy

- Keep commits focused and reviewable.
- Subject format: `feat(area): ...`, `fix(area): ...`, etc.
- Include `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
  trailer in commit messages when working with AI assistants.

### PR policy

- Open PR against `main` only after local tests pass.
- Fill PR template completely: behavior summary, test evidence, documentation.
- Require CI green before merge.
- Prefer squash merge for linear history.

### Post-merge hygiene

After merge:

1. Sync local `main` with remote.
2. Delete merged feature branch locally/remotely.
3. Update project summary artifacts if the change affects roadmap.

---

## 10. Build Presets and Scripts

The project provides standard build and workflow scripts matching project-crown:

- `./dev.sh build` — Configure and build the debug preset
- `./dev.sh test` — Run test suite
- `./dev.sh demo` — Build and run debug executable
- `./tests.sh` — Run full test suite with detailed output
- `./release.sh` — Build optimized release bundle
- `./fps-release.sh` — Build release with dev overlay for performance testing
- `./asan.sh` — Build with AddressSanitizer (memory debugging)
- `./profile.sh` — Build with debug symbols for profiling
- `./docs.sh` — Generate Doxygen documentation

### Build presets (CMakePresets.json)

- `debug`: Default development build with sanitizers and debug info
- `release`: Optimized build (-O3), no sanitizers
- `profile`: RelWithDebInfo for profiling
- `coverage`: Debug + gcov instrumentation
- `mutation`: Debug without sanitizers for mutation testing

---

## 11. Code Organization

### ECS (Entity-Component System)

- Entities are identified by opaque 64-bit handles.
- Components are POD structs stored in dense arrays per-component.
- Systems iterate over component sets in explicit order.
- Component data is separate from control flow for cache efficiency.

### Ability Definitions

- Abilities are defined in YAML or JSON files in `assets/abilities/`.
- Schema includes: name, movement pattern, hitbox shape/size, graphics asset,
  parameters (damage, cooldown, duration, etc.).
- Loader parses definitions and registers components.

### Screen System

- Screens are state machines (Splash → Title → CharSelect → Gameplay, etc.).
- Each screen has an `Update()` and `Render()` method.
- `ScreenManager` handles transitions and lifetime.
- ImGui UI elements are rendered within screen render methods.

---

## 12. Performance and Determinism

- Avoid dynamic memory allocation in hot paths (per-frame updates).
- Use fixed-size containers or pre-allocated object pools.
- Prefer data-driven layouts (SOA) for component data.
- Ensure ability processing is deterministic (fixed-point math where needed).
- Document performance expectations in function comments.

---

## 13. Third-Party APIs

Third-party APIs (BGFX, ImGui, SDL2, miniaudio) are **first-class dependencies**.
Code that calls them must:

1. Include a brief comment explaining *why* the API call is made.
2. Handle error returns explicitly — do not assume success.
3. Keep platform-specific calls isolated behind abstraction layers.

---

## 14. Quality Gates Before Commit

1. **Compilation:** Build succeeds for both debug and release presets.
2. **Tests:** All tests pass (`./tests.sh` or `ctest --preset debug`).
3. **Formatting:** `clang-format` applied to all modified C/C++ files.
4. **No new warnings:** Compile output is clean (-Werror enforces this).
5. **Documentation:** Functions and non-obvious logic are documented.

---

## 15. Implemented Functionality & Status

This document will be updated as features are implemented. See `PLAN.md` for
the current development roadmap and status of each milestone.

Current implementation status:
- ✓ Build infrastructure (CMake, presets, scripts)
- ✓ Code formatting rules (.clang-format, .editorconfig)
- ✓ Documentation template (Doxyfile)
- ⏳ Compilation baseline (in progress)
- ⏳ UI screen stubs (planned)
- ⏳ ECS framework (planned)
- ⏳ Ability system (planned)
