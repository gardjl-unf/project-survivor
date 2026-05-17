/**
 * @file ecs.c
 * @brief Entity-Component System implementation.
 *
 * This is a basic ECS using dense SOA (Structure of Arrays) storage.
 * Stub implementation for initial compilation.
 */

#include <stdlib.h>
#include <string.h>
#include "survivor/ecs.h"

typedef struct {
    char* name;
    size_t size;
    size_t alignment;
    void* data;
} ComponentStorage;

struct SurvivorECS {
    survivor_entity_t* entities;
    size_t num_entities;
    size_t max_entities;

    ComponentStorage* components;
    size_t num_components;
    size_t max_components;
};

SurvivorECS* survivor_ecs_create(size_t max_entities)
{
    SurvivorECS* ecs = (SurvivorECS*)malloc(sizeof(SurvivorECS));
    if (!ecs) {
        return NULL;
    }

    ecs->entities = (survivor_entity_t*)malloc(max_entities * sizeof(survivor_entity_t));
    if (!ecs->entities) {
        free(ecs);
        return NULL;
    }

    ecs->components = (ComponentStorage*)malloc(16 * sizeof(ComponentStorage));
    if (!ecs->components) {
        free(ecs->entities);
        free(ecs);
        return NULL;
    }

    ecs->num_entities = 0;
    ecs->max_entities = max_entities;
    ecs->num_components = 0;
    ecs->max_components = 16;

    return ecs;
}

void survivor_ecs_destroy(SurvivorECS* ecs)
{
    if (!ecs) {
        return;
    }

    for (size_t i = 0; i < ecs->num_components; i++) {
        free(ecs->components[i].name);
        free(ecs->components[i].data);
    }

    free(ecs->components);
    free(ecs->entities);
    free(ecs);
}

survivor_entity_t survivor_entity_create(SurvivorECS* ecs)
{
    if (!ecs || ecs->num_entities >= ecs->max_entities) {
        return SURVIVOR_ENTITY_INVALID;
    }

    survivor_entity_t entity_id = (survivor_entity_t)(ecs->num_entities + 1);
    ecs->entities[ecs->num_entities++] = entity_id;

    return entity_id;
}

void survivor_entity_destroy(SurvivorECS* ecs, survivor_entity_t entity)
{
    if (!ecs) {
        return;
    }

    for (size_t i = 0; i < ecs->num_entities; i++) {
        if (ecs->entities[i] == entity) {
            ecs->entities[i] = ecs->entities[--ecs->num_entities];
            break;
        }
    }
}

survivor_component_t survivor_component_register(SurvivorECS* ecs, const char* name,
                                                  size_t size, size_t alignment)
{
    if (!ecs || ecs->num_components >= ecs->max_components) {
        return SURVIVOR_COMPONENT_INVALID;
    }

    ComponentStorage* comp = &ecs->components[ecs->num_components];
    comp->name = (char*)malloc(strlen(name) + 1);
    if (!comp->name) {
        return SURVIVOR_COMPONENT_INVALID;
    }

    strcpy(comp->name, name);
    comp->size = size;
    comp->alignment = alignment;
    comp->data = malloc(size * ecs->max_entities);
    if (!comp->data) {
        free(comp->name);
        return SURVIVOR_COMPONENT_INVALID;
    }

    return (survivor_component_t)(ecs->num_components++);
}

int survivor_entity_add_component(SurvivorECS* ecs, survivor_entity_t entity,
                                   survivor_component_t comp_id, const void* data)
{
    if (!ecs || comp_id >= ecs->num_components) {
        return -1;
    }

    ComponentStorage* comp = &ecs->components[comp_id];
    void* comp_data = (char*)comp->data + comp->size * entity;

    if (data) {
        memcpy(comp_data, data, comp->size);
    } else {
        memset(comp_data, 0, comp->size);
    }

    return 0;
}

void* survivor_entity_get_component(SurvivorECS* ecs, survivor_entity_t entity,
                                     survivor_component_t comp_id)
{
    if (!ecs || comp_id >= ecs->num_components) {
        return NULL;
    }

    ComponentStorage* comp = &ecs->components[comp_id];
    return (char*)comp->data + comp->size * entity;
}

int survivor_entity_set_component(SurvivorECS* ecs, survivor_entity_t entity,
                                   survivor_component_t comp_id, const void* data)
{
    if (!ecs || comp_id >= ecs->num_components || !data) {
        return -1;
    }

    ComponentStorage* comp = &ecs->components[comp_id];
    void* comp_data = (char*)comp->data + comp->size * entity;
    memcpy(comp_data, data, comp->size);

    return 0;
}

int survivor_entity_remove_component(SurvivorECS* ecs, survivor_entity_t entity,
                                      survivor_component_t comp_id)
{
    if (!ecs || comp_id >= ecs->num_components) {
        return -1;
    }

    ComponentStorage* comp = &ecs->components[comp_id];
    void* comp_data = (char*)comp->data + comp->size * entity;
    memset(comp_data, 0, comp->size);

    return 0;
}

int survivor_entity_has_component(SurvivorECS* ecs, survivor_entity_t entity,
                                   survivor_component_t comp_id)
{
    if (!ecs || comp_id >= ecs->num_components) {
        return 0;
    }

    ComponentStorage* comp = &ecs->components[comp_id];
    void* comp_data = (char*)comp->data + comp->size * entity;

    // Check if component data is non-zero (simplified check)
    for (size_t i = 0; i < comp->size; i++) {
        if (((char*)comp_data)[i] != 0) {
            return 1;
        }
    }

    return 0;
}
