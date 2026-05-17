# Survivor - Vampire Survivors Clone

A fast-action dungeon roguelike inspired by Vampire Survivors, built with a custom C/C++ engine using BGFX rendering and an Entity-Component System (ECS) for ability management.

## Project Status

**Phase 1: Infrastructure Baseline** ✓ COMPLETE

- ✓ Build system (CMake 3.21+, Ninja)
- ✓ Debug and Release builds (both compile without warnings)
- ✓ C17 core simulation + C++20 platform layer
- ✓ Basic ECS framework
- ✓ Ability system design (YAML/JSON schema in progress)
- ✓ Code formatting rules (`.clang-format`, `.editorconfig`)
- ✓ Doxygen documentation configuration
- ✓ CTest framework with sample tests
- ⏳ GitHub repository (creating now)
- ⏳ ImGui UI stubs (splash screen, title screen, character select)
- ⏳ Cross-compilation pipeline investigation

## Building

### Prerequisites

- CMake 3.21+
- Ninja build system
- GCC or Clang compiler (C17 + C++20 support)
- Standard development libraries

### Quick Start

```bash
# Debug build
./dev.sh build

# Test
./tests.sh

# Demo (build + run)
./dev.sh demo

# Release build
./release.sh
```

### Build Presets

- `debug` - Development with sanitizers (-fsanitize=address,undefined)
- `release` - Optimized (-O3), no sanitizers
- `profile` - Release with debug symbols for profiling
- `coverage` - Debug + gcov instrumentation
- `mutation` - Debug without sanitizers (for mutation testing)

## Project Structure

```
project-survivor/
├── include/survivor/       # Public C headers (simulation API)
│   ├── ecs.h              # Entity-Component System interface
│   ├── ability_system.h   # Ability definitions and components
│   └── platform/          # C++ platform layer interfaces
│       └── renderer.hpp   # BGFX renderer interface
├── src/
│   ├── core/              # C17 simulation core
│   │   ├── ecs.c         # ECS storage and queries
│   │   ├── ability_system.c  # Ability loading and management
│   │   └── math_utils.c  # Utility math functions
│   ├── platform/          # C++20 platform shell
│   │   ├── app.cpp       # Main application state
│   │   ├── renderer.cpp  # BGFX integration
│   │   ├── ui_layer.cpp  # ImGui integration
│   │   ├── screen_manager.cpp # Scene/screen state management
│   │   ├── texture_manager.cpp # Texture loading
│   │   └── greyscale_effect.cpp # Post-process effects
│   └── main.cpp          # Application entry point
├── tests/                 # CTest test suite
│   ├── test_ecs.c       # ECS unit tests
│   └── CMakeLists.txt    # Test configuration
├── assets/               # Game data
│   ├── sprites/         # Sprite sheets and assets
│   ├── audio/          # Music and SFX
│   └── abilities/      # Ability definition files (YAML/JSON)
├── shaders/            # BGFX shader sources
├── scripts/            # Build and utility scripts
├── CMakeLists.txt      # Main build configuration
├── CMakePresets.json   # Build presets
├── .clang-format       # Code formatting (LLVM style, 4-space, 120-col)
├── .editorconfig       # Editor settings
├── Doxyfile           # Documentation generation
└── AGENTS.md          # Development guidelines
```

## Development Workflow

### Adding a Feature

1. Create a branch: `git checkout -b feat/area-name`
2. Write tests first (TDD style)
3. Implement feature
4. Run `clang-format -i <file>` on all modified C/C++ files
5. Run tests: `./tests.sh`
6. Create pull request against `main`

### Code Standards

See [`AGENTS.md`](./AGENTS.md) for detailed guidelines:

- **Language:** C17 (core) + C++20 (platform)
- **Formatting:** `clang-format` with LLVM style
- **Naming:** PascalCase for types/functions, camelCase for variables
- **Documentation:** Doxygen comments required for all public functions
- **Testing:** Every change requires tests
- **Build:** Zero compiler warnings, sanitizers enabled in debug

## ECS (Entity-Component System)

### Basic Usage

```c
// Create ECS with max 1000 entities
SurvivorECS* ecs = survivor_ecs_create(1000);

// Create an entity
survivor_entity_t player = survivor_entity_create(ecs);

// Register a component type
survivor_component_t position_comp = survivor_component_register(
    ecs, "Position", sizeof(Position), alignof(Position)
);

// Add component to entity
Position pos = {10.0f, 20.0f};
survivor_entity_add_component(ecs, player, position_comp, &pos);

// Query component
Position* p = (Position*)survivor_entity_get_component(ecs, player, position_comp);

// Cleanup
survivor_entity_destroy(ecs, player);
survivor_ecs_destroy(ecs);
```

### Component Design

Components are POD (Plain Old Data) structs with dense storage per-component type. This layout maximizes cache efficiency for bulk operations.

## Ability System

Abilities are data-driven and defined in YAML or JSON files. Each ability specifies:

- **Movement pattern:** linear, parabolic, homing, spiral, or stationary
- **Hitbox:** circle, rectangle, or polygon collision shapes
- **Graphics:** sprite/texture assets
- **Parameters:** damage, cooldown, duration

### Ability File Format (Planned)

```yaml
abilities:
  - id: "fireball"
    name: "Fireball"
    base_damage: 25.0
    cooldown: 1.5
    duration: 2.0
    movement: linear
    movement_speed: 100.0
    hitbox_type: circle
    hitbox_radius: 16.0
    asset_sprite: "effects/fireball.sprites.cfg"
```

Full schema and loader will be implemented in Phase 2.

## Performance Targets

- **Frame rate:** 60 FPS minimum on reference hardware
- **Memory:** <100MB resident (adjustable with entity/ability limits)
- **Update time:** <5ms per frame (deterministic simulation)
- **Render time:** <10ms per frame (at 1080p)

## Cross-Platform Support (Phase 4+)

Current scope: Linux desktop. Planned targets:

- Windows (x86-64)
- macOS (Intel + Apple Silicon)
- iOS
- Android

Graphics abstraction for BGFX backends:
- OpenGL ES / OpenGL
- Metal (macOS, iOS)
- Direct3D 11 (Windows)
- Vulkan (where available)

Input abstraction:
- Keyboard/Mouse (desktop)
- Touch (mobile)
- Controller support (via SDL2)

## Third-Party Dependencies

- **BGFX** - Rendering framework
- **Dear ImGui** - UI toolkit (non-docking branch)
- **SDL2** - Input and platform abstraction
- **miniaudio** - Audio playback
- **zlib** - Compression (for asset bundling)

Full dependency setup and integration planned for Phase 2.

## Documentation

Generated documentation available via:

```bash
./docs.sh
```

Output appears in `docs/html/index.html`.

## Roadmap

### Phase 1: Infrastructure ✓
- Build system, code standards, basic ECS

### Phase 2: UI and Core Gameplay (In Progress)
- Splash, title, and character select screens
- Entity-Component System with real data
- Ability loading and execution

### Phase 3: Game Content
- Character definitions and stats
- Ability implementations
- Enemy archetypes
- Level generation

### Phase 4: Cross-Platform
- Android build target
- iOS build target
- Windows/macOS optimization
- Controller support

### Phase 5: Polish & Release
- Performance profiling and optimization
- Asset pipeline and content tools
- UI polish and accessibility
- Steam integration (stretch goal)

## Contributing

See [`AGENTS.md`](./AGENTS.md) for coding guidelines and development protocol.

## License

[To be determined]

---

**Project Survivor** is a learning project exploring game architecture, ECS design, and cross-platform game development. It is not affiliated with Vampire Survivors or any commercial project.
