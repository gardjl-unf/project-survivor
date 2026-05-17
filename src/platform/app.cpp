/**
 * @file app.cpp
 * @brief Main application context.
 */

namespace survivor::platform {

class Application {
public:
    bool Initialize(int width, int height, const char* title);
    void Shutdown();
    bool IsRunning() const;
    void Update();
    void Render();

private:
    bool m_Running = false;
};

bool Application::Initialize(int width, int height, const char* title)
{
    m_Running = true;
    return true;
}

void Application::Shutdown()
{
    m_Running = false;
}

bool Application::IsRunning() const
{
    return m_Running;
}

void Application::Update()
{
}

void Application::Render()
{
}

}  // namespace survivor::platform
