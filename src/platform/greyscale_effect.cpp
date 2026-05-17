/**
 * @file greyscale_effect.cpp
 * @brief Greyscale/desaturation post-process effect (stub).
 *
 * Ported from project-crown rendering pipeline.
 * Implements a post-process pass that desaturates the framebuffer to grayscale.
 */

namespace survivor::platform {

/**
 * @brief Apply greyscale desaturation to the rendered frame.
 *
 * Uses the standard luminance formula: gray = 0.299*R + 0.587*G + 0.114*B
 */
void ApplyGreyscaleEffect()
{
    // Stub: BGFX post-process pass
}

}  // namespace survivor::platform
