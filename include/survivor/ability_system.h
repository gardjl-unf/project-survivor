/**
 * @file ability_system.h
 * @brief Ability and ability component definitions.
 *
 * Abilities are data-driven effects described in YAML or JSON.
 * This module provides the component types and loading infrastructure.
 */

#ifndef SURVIVOR_ABILITY_SYSTEM_H
#define SURVIVOR_ABILITY_SYSTEM_H

#include <stdint.h>
#include "ecs.h"

#ifdef __cplusplus
extern "C" {
#endif

/** @brief Unique identifier for an ability. */
typedef uint32_t survivor_ability_id_t;

/** @brief Invalid ability ID. */
#define SURVIVOR_ABILITY_ID_INVALID ((survivor_ability_id_t)~0U)

/**
 * @brief Ability component: attached to an entity to define an active ability.
 *
 * This component represents an ability instance on an entity (e.g., a projectile
 * or effect spawned from an ability execution).
 */
typedef struct {
    survivor_ability_id_t ability_id;  /**< Reference to ability definition */
    float elapsed_time;                 /**< Time elapsed since ability activation */
    float duration;                     /**< Total duration of the ability effect */
    float cooldown_remaining;           /**< Cooldown counter (0 = ready) */
    uint32_t owner_id;                  /**< ID of entity that owns this ability */
    int active;                         /**< 1 if active, 0 if dormant */
} SurvivorAbilityComponent;

/**
 * @brief Movement pattern descriptor for abilities.
 *
 * Describes how an ability projectile or effect moves.
 */
typedef enum {
    SURVIVOR_MOVEMENT_NONE = 0,      /**< Stationary (on caster) */
    SURVIVOR_MOVEMENT_LINEAR,        /**< Straight line at constant velocity */
    SURVIVOR_MOVEMENT_PARABOLIC,     /**< Projectile arc */
    SURVIVOR_MOVEMENT_HOMING,        /**< Seeks target */
    SURVIVOR_MOVEMENT_SPIRAL,        /**< Spiral pattern */
} SurvivorMovementType;

/**
 * @brief Hitbox shape for collision/damage.
 */
typedef enum {
    SURVIVOR_HITBOX_NONE = 0,      /**< No collision */
    SURVIVOR_HITBOX_CIRCLE,        /**< Circular hitbox */
    SURVIVOR_HITBOX_RECT,          /**< Rectangular hitbox */
    SURVIVOR_HITBOX_POLYGON,       /**< Polygonal hitbox */
} SurvivorHitboxType;

/**
 * @brief Ability definition (loaded from asset file).
 *
 * This is the parsed, read-only ability data. Instances are looked up
 * via survivor_ability_id_t from a registry.
 */
typedef struct {
    survivor_ability_id_t id;
    const char* name;                   /**< Human-readable name */
    const char* asset_sprite;           /**< Sprite/texture asset key */
    float base_damage;                  /**< Base damage value */
    float cooldown;                     /**< Cooldown in seconds */
    float duration;                     /**< Effect duration in seconds */
    SurvivorMovementType movement;      /**< Movement pattern */
    float movement_speed;               /**< Speed for linear movement */
    SurvivorHitboxType hitbox_type;     /**< Collision shape */
    float hitbox_radius;                /**< Radius (for circle) or half-extent */
    /* Additional fields for future expansion: knockback, status effects, etc. */
} SurvivorAbilityDef;

/**
 * @brief Ability registry (loaded from asset files).
 *
 * Opaque handle to the collection of loaded ability definitions.
 */
typedef struct SurvivorAbilityRegistry SurvivorAbilityRegistry;

/**
 * @brief Create an ability registry.
 *
 * @return New registry instance, or NULL on allocation failure.
 */
SurvivorAbilityRegistry* survivor_ability_registry_create(void);

/**
 * @brief Destroy an ability registry and free all definitions.
 *
 * @param[in,out] registry Ability registry.
 */
void survivor_ability_registry_destroy(SurvivorAbilityRegistry* registry);

/**
 * @brief Load ability definitions from a YAML/JSON file.
 *
 * Format TBD: will support both YAML and JSON. File path is relative to
 * the project root or assets/ directory.
 *
 * @param[in,out] registry Ability registry.
 * @param[in] filepath Path to ability definition file.
 * @return 0 on success, non-zero on parse or I/O failure.
 */
int survivor_ability_registry_load_file(SurvivorAbilityRegistry* registry, const char* filepath);

/**
 * @brief Look up an ability definition by ID.
 *
 * @param[in] registry Ability registry.
 * @param[in] ability_id Ability ID.
 * @return Pointer to ability definition (valid for lifetime of registry), or NULL if not found.
 */
const SurvivorAbilityDef* survivor_ability_registry_get(SurvivorAbilityRegistry* registry,
                                                        survivor_ability_id_t ability_id);

/**
 * @brief Register the ability component with the ECS.
 *
 * Should be called once at initialization to allocate ECS storage for ability components.
 *
 * @param[in,out] ecs ECS context.
 * @return Component ID for ability components, or SURVIVOR_COMPONENT_INVALID on failure.
 */
survivor_component_t survivor_ability_component_register(SurvivorECS* ecs);

#ifdef __cplusplus
}
#endif

#endif /* SURVIVOR_ABILITY_SYSTEM_H */
