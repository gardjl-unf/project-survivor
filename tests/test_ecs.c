/**
 * @file test_ecs.c
 * @brief Basic ECS tests.
 */

#include <stdio.h>
#include "survivor/ecs.h"

int main(void)
{
    printf("Running ECS tests...\n");

    // Create ECS
    SurvivorECS* ecs = survivor_ecs_create(1000);
    if (!ecs) {
        printf("FAIL: Could not create ECS\n");
        return 1;
    }

    // Create an entity
    survivor_entity_t entity = survivor_entity_create(ecs);
    if (entity == SURVIVOR_ENTITY_INVALID) {
        printf("FAIL: Could not create entity\n");
        survivor_ecs_destroy(ecs);
        return 1;
    }

    printf("PASS: Basic ECS operations\n");

    survivor_ecs_destroy(ecs);
    return 0;
}
