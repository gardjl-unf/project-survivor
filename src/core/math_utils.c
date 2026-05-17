/**
 * @file math_utils.c
 * @brief Utility math functions.
 */

#include <math.h>

/**
 * @brief Clamp a value between min and max.
 */
float clamp_f(float value, float min_val, float max_val)
{
    if (value < min_val) return min_val;
    if (value > max_val) return max_val;
    return value;
}

/**
 * @brief Linear interpolation between two values.
 */
float lerp_f(float a, float b, float t)
{
    return a + (b - a) * t;
}
