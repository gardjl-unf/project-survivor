/**
 * @file texture_manager.cpp
 * @brief Texture loading and caching (stub).
 */

namespace survivor::platform {

class TextureManager {
public:
    bool Initialize();
    void Shutdown();
};

bool TextureManager::Initialize()
{
    return true;
}

void TextureManager::Shutdown()
{
}

}  // namespace survivor::platform
