/**
 * @file ui_layer.cpp
 * @brief ImGui UI layer (stub).
 */

namespace survivor::platform {

class UILayer {
public:
    bool Initialize();
    void Shutdown();
    void BeginFrame();
    void EndFrame();
};

bool UILayer::Initialize()
{
    return true;
}

void UILayer::Shutdown()
{
}

void UILayer::BeginFrame()
{
}

void UILayer::EndFrame()
{
}

}  // namespace survivor::platform
