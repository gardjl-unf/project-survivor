cmake_minimum_required(VERSION 3.21)
project(survivor LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build options
option(SURVIVOR_ENABLE_SANITIZERS "Enable ASan/UBSan in Debug builds" ON)
option(SURVIVOR_ENABLE_COVERAGE "Enable gcov instrumentation for coverage builds" OFF)
option(SURVIVOR_ENABLE_GTEST "Use GoogleTest for C++ tests when available" ON)
option(SURVIVOR_ENABLE_DEV_OVERLAY "Enable development FPS/diagnostic debug overlays" ON)
option(SURVIVOR_ALLOW_UNUSED_CODE "Allow unused functions/parameters/variables during active development" ON)
option(SURVIVOR_FETCH_IMGUI_DEPS "Auto-fetch bgfx source tree for ImGui bridge when missing" ON)
option(SURVIVOR_FETCH_MINIAUDIO_DEPS "Auto-fetch miniaudio.h when missing" ON)
option(SURVIVOR_FETCH_BOOST_MATH_DEPS "Auto-fetch Boost headers when missing" ON)
option(SURVIVOR_FETCH_BX_DEPS "Auto-fetch bx headers when missing" ON)
set(SURVIVOR_ENABLE_IMGUI ON)

# Compiler warnings
if(MSVC)
  add_compile_options(/W4 /WX)
else()
  add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# Allow unused code during development
if(SURVIVOR_ALLOW_UNUSED_CODE)
  if(MSVC)
    add_compile_options(
      /wd4100  # unreferenced formal parameter
      /wd4101  # unreferenced local variable
      /wd4189  # initialized but not referenced local variable
      /wd4505  # unreferenced local function has been removed
    )
  else()
    add_compile_options(
      -Wno-unused
      -Wno-unused-parameter
      -Wno-unused-variable
      -Wno-unused-function
      -Wno-unused-but-set-variable
    )
  endif()
endif()

# Sanitizers (Debug only)
if(SURVIVOR_ENABLE_SANITIZERS AND NOT MSVC)
  if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    add_compile_options(
      $<$<CONFIG:Debug>:-fno-omit-frame-pointer>
      $<$<CONFIG:Debug>:-fsanitize=address,undefined>
    )
    add_link_options($<$<CONFIG:Debug>:-fsanitize=address,undefined>)
  endif()
endif()

# Coverage instrumentation
if(SURVIVOR_ENABLE_COVERAGE)
  if(MSVC)
    message(FATAL_ERROR "SURVIVOR_ENABLE_COVERAGE requires GCC/Clang gcov toolchain; MSVC is unsupported.")
  endif()
  if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    add_compile_options(-O0 -g --coverage)
    add_link_options(--coverage)
  else()
    message(FATAL_ERROR "SURVIVOR_ENABLE_COVERAGE requires GCC or Clang.")
  endif()
endif()

# Testing
include(CTest)
find_package(PkgConfig QUIET)
find_package(Python3 COMPONENTS Interpreter QUIET)
if(SURVIVOR_ENABLE_GTEST)
  find_package(GTest QUIET)
endif()

# Core simulation library (C)
add_library(survivor_core STATIC
  src/core/ecs.c
  src/core/math_utils.c
  src/core/ability_system.c
)

target_include_directories(survivor_core PUBLIC include)
target_include_directories(survivor_core PRIVATE src)

# Platform/rendering layer (C++)
add_library(survivor_platform STATIC
  src/platform/app.cpp
  src/platform/renderer.cpp
  src/platform/ui_layer.cpp
  src/platform/screen_manager.cpp
  src/platform/texture_manager.cpp
  src/platform/greyscale_effect.cpp
)

target_include_directories(survivor_platform PUBLIC include)
target_include_directories(survivor_platform PRIVATE src)

# Main executable
add_executable(survivor
  src/main.cpp
)

target_link_libraries(survivor PRIVATE
  survivor_core
  survivor_platform
)

# Third-party dependencies - simplified for now
# Full setup will include BGFX, ImGui, miniaudio, SDL2, etc.

if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
