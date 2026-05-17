/**
 * @file ecs.h
 * @brief Entity-Component System (ECS) core interfaces.
 *
 * This header defines the core ECS API for managing entities and components.
 * The ECS uses dense array storage (Structure of Arrays) for cache efficiency.
 */

#ifndef SURVIVOR_ECS_H
#define SURVIVOR_ECS_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @brief Opaque entity handle (64-bit). */
typedef uint64_t survivor_entity_t;

/** @brief Invalid entity handle constant. */
#define SURVIVOR_ENTITY_INVALID ((survivor_entity_t)0)

/** @brief Opaque component handle for registration. */
typedef uint32_t survivor_component_t;

/** @brief Invalid component handle constant. */
#define SURVIVOR_COMPONENT_INVALID ((survivor_component_t)~0U)

/**
 * @brief ECS context. Opaque handle to the entity store.
 */
typedef struct SurvivorECS SurvivorECS;

/**
 * @brief Create an ECS instance.
 *
 * @param[in] max_entities Maximum number of entities allowed.
 * @return Allocated ECS context, or NULL on failure.
 */
SurvivorECS* survivor_ecs_create(size_t max_entities);

/**
 * @brief Destroy an ECS instance and free all resources.
 *
 * @param[in,out] ecs ECS context to destroy.
 */
void survivor_ecs_destroy(SurvivorECS* ecs);

/**
 * @brief Create a new entity.
 *
 * @param[in,out] ecs ECS context.
 * @return New entity handle, or SURVIVOR_ENTITY_INVALID on failure.
 */
survivor_entity_t survivor_entity_create(SurvivorECS* ecs);

/**
 * @brief Destroy an entity and remove all components.
 *
 * @param[in,out] ecs ECS context.
 * @param[in] entity Entity handle.
 */
void survivor_entity_destroy(SurvivorECS* ecs, survivor_entity_t entity);

/**
 * @brief Register a component type with the ECS.
 *
 * Component registration reserves a component type and allocates storage.
 *
 * @param[in,out] ecs ECS context.
 * @param[in] name Human-readable component name (e.g., "Position").
 * @param[in] size Size of each component instance in bytes.
 * @param[in] alignment Alignment requirement in bytes.
 * @return Component handle for future reference, or SURVIVOR_COMPONENT_INVALID.
 */
survivor_component_t survivor_component_register(SurvivorECS* ecs, const char* name,
                                                  size_t size, size_t alignment);

/**
 * @brief Add a component instance to an entity.
 *
 * @param[in,out] ecs ECS context.
 * @param[in] entity Entity handle.
 * @param[in] comp_id Component type.
 * @param[in] data Pointer to component data (copied in). May be NULL for zero-init.
 * @return 0 on success, non-zero on failure (entity not found, component already present, etc.).
 */
int survivor_entity_add_component(SurvivorECS* ecs, survivor_entity_t entity,
                                   survivor_component_t comp_id, const void* data);

/**
 * @brief Get a component instance from an entity.
 *
 * @param[in] ecs ECS context.
 * @param[in] entity Entity handle.
 * @param[in] comp_id Component type.
 * @return Pointer to component data, or NULL if not present.
 */
void* survivor_entity_get_component(SurvivorECS* ecs, survivor_entity_t entity,
                                     survivor_component_t comp_id);

/**
 * @brief Update a component instance on an entity.
 *
 * @param[in,out] ecs ECS context.
 * @param[in] entity Entity handle.
 * @param[in] comp_id Component type.
 * @param[in] data Pointer to new component data (copied in).
 * @return 0 on success, non-zero if component not found.
 */
int survivor_entity_set_component(SurvivorECS* ecs, survivor_entity_t entity,
                                   survivor_component_t comp_id, const void* data);

/**
 * @brief Remove a component from an entity.
 *
 * @param[in,out] ecs ECS context.
 * @param[in] entity Entity handle.
 * @param[in] comp_id Component type.
 * @return 0 on success, non-zero if component not present.
 */
int survivor_entity_remove_component(SurvivorECS* ecs, survivor_entity_t entity,
                                      survivor_component_t comp_id);

/**
 * @brief Check if an entity has a component.
 *
 * @param[in] ecs ECS context.
 * @param[in] entity Entity handle.
 * @param[in] comp_id Component type.
 * @return 1 if present, 0 otherwise.
 */
int survivor_entity_has_component(SurvivorECS* ecs, survivor_entity_t entity,
                                   survivor_component_t comp_id);

#ifdef __cplusplus
}
#endif

#endif /* SURVIVOR_ECS_H */
