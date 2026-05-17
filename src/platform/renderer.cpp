/**
 * @file renderer.cpp
 * @brief BGFX renderer implementation (stub).
 */

#include "survivor/platform/renderer.hpp"

namespace survivor::platform {

bool Renderer::Initialize(uint32_t width, uint32_t height)
{
    m_Width = width;
    m_Height = height;
    m_Initialized = true;
    return true;
}

void Renderer::Shutdown()
{
    m_Initialized = false;
}

void Renderer::BeginFrame()
{
    // Stub: BGFX frame begin
}

void Renderer::EndFrame()
{
    // Stub: BGFX frame end
}

uint32_t Renderer::GetWidth() const
{
    return m_Width;
}

uint32_t Renderer::GetHeight() const
{
    return m_Height;
}

bool Renderer::IsInitialized() const
{
    return m_Initialized;
}

}  // namespace survivor::platform
