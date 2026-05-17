/**
 * @file ability_system.c
 * @brief Ability system implementation (stub).
 *
 * This is a minimal stub for initial compilation. Full implementation
 * will include YAML/JSON parsing and ability definition loading.
 */

#include <stdlib.h>
#include <string.h>
#include "survivor/ability_system.h"

struct SurvivorAbilityRegistry {
    SurvivorAbilityDef* abilities;
    size_t num_abilities;
    size_t max_abilities;
};

SurvivorAbilityRegistry* survivor_ability_registry_create(void)
{
    SurvivorAbilityRegistry* registry = (SurvivorAbilityRegistry*)malloc(sizeof(SurvivorAbilityRegistry));
    if (!registry) {
        return NULL;
    }

    registry->abilities = (SurvivorAbilityDef*)malloc(64 * sizeof(SurvivorAbilityDef));
    if (!registry->abilities) {
        free(registry);
        return NULL;
    }

    registry->num_abilities = 0;
    registry->max_abilities = 64;

    return registry;
}

void survivor_ability_registry_destroy(SurvivorAbilityRegistry* registry)
{
    if (!registry) {
        return;
    }

    for (size_t i = 0; i < registry->num_abilities; i++) {
        free((void*)registry->abilities[i].name);
        free((void*)registry->abilities[i].asset_sprite);
    }

    free(registry->abilities);
    free(registry);
}

int survivor_ability_registry_load_file(SurvivorAbilityRegistry* registry, const char* filepath)
{
    if (!registry || !filepath) {
        return -1;
    }

    // Stub: In full implementation, parse YAML/JSON file and populate registry
    return 0;
}

const SurvivorAbilityDef* survivor_ability_registry_get(SurvivorAbilityRegistry* registry,
                                                        survivor_ability_id_t ability_id)
{
    if (!registry) {
        return NULL;
    }

    for (size_t i = 0; i < registry->num_abilities; i++) {
        if (registry->abilities[i].id == ability_id) {
            return &registry->abilities[i];
        }
    }

    return NULL;
}

survivor_component_t survivor_ability_component_register(SurvivorECS* ecs)
{
    if (!ecs) {
        return SURVIVOR_COMPONENT_INVALID;
    }

    return survivor_component_register(ecs, "AbilityComponent", sizeof(SurvivorAbilityComponent), 8);
}
