/**
 * @file renderer.hpp
 * @brief BGFX-based rendering interface.
 */

#ifndef SURVIVOR_PLATFORM_RENDERER_HPP
#define SURVIVOR_PLATFORM_RENDERER_HPP

#include <cstdint>

namespace survivor::platform {

/**
 * @brief Renderer context for BGFX integration.
 */
class Renderer {
public:
    /**
     * @brief Initialize the renderer.
     *
     * @param[in] width Window width in pixels.
     * @param[in] height Window height in pixels.
     * @return true on success, false on failure.
     */
    bool Initialize(uint32_t width, uint32_t height);

    /**
     * @brief Shut down the renderer and clean up resources.
     */
    void Shutdown();

    /**
     * @brief Begin a new frame for rendering.
     *
     * Called at the start of each render pass.
     */
    void BeginFrame();

    /**
     * @brief End the current frame and submit to display.
     *
     * Called at the end of each render pass.
     */
    void EndFrame();

    /**
     * @brief Get the current backbuffer width.
     */
    uint32_t GetWidth() const;

    /**
     * @brief Get the current backbuffer height.
     */
    uint32_t GetHeight() const;

    /**
     * @brief Check if renderer is initialized.
     */
    bool IsInitialized() const;

private:
    uint32_t m_Width = 0;
    uint32_t m_Height = 0;
    bool m_Initialized = false;
};

}  // namespace survivor::platform

#endif /* SURVIVOR_PLATFORM_RENDERER_HPP */
