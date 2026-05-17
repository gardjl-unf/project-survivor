# Tests CMakeLists.txt

# Basic test setup
add_executable(test_ecs
  test_ecs.c
)
target_link_libraries(test_ecs survivor_core)

add_test(NAME ecs COMMAND test_ecs)
