/**
 * @file screen_manager.cpp
 * @brief Screen/scene state manager (stub).
 */

namespace survivor::platform {

class ScreenManager {
public:
    bool Initialize();
    void Shutdown();
    void Update();
    void Render();
};

bool ScreenManager::Initialize()
{
    return true;
}

void ScreenManager::Shutdown()
{
}

void ScreenManager::Update()
{
}

void ScreenManager::Render()
{
}

}  // namespace survivor::platform
