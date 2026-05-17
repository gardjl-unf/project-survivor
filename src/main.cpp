/**
 * @file main.cpp
 * @brief Application entry point.
 */

#include <cstdio>
#include <exception>

int main(int argc, char* argv[])
{
    try {
        printf("Survivor - Vampire Survivors Clone\n");
        printf("Initializing...\n");

        // Initialize application systems
        // TODO: Renderer initialization
        // TODO: ImGui initialization
        // TODO: ECS initialization
        // TODO: Screen manager initialization

        printf("Application running\n");

        // Main loop (stub)
        bool running = true;
        int frames = 0;
        while (running && frames < 100) {
            // Update
            // Render
            frames++;
        }

        printf("Application shutdown\n");

        // Cleanup systems
        // TODO: Renderer shutdown
        // TODO: ImGui shutdown
        // TODO: ECS shutdown
        // TODO: Screen manager shutdown

        return 0;
    } catch (const std::exception& e) {
        fprintf(stderr, "Fatal error: %s\n", e.what());
        return 1;
    } catch (...) {
        fprintf(stderr, "Unknown fatal error\n");
        return 1;
    }
}
