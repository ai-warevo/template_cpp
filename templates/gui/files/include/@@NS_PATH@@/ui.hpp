#ifndef @@NS_UPPER@@_UI_HPP
#define @@NS_UPPER@@_UI_HPP

#include <memory>

@@NS_OPEN@@

class PanelRegistry;

/// Root UI class that orchestrates all panels and rendering.
/// Renders fullscreen tab bar with panel delegation.
class UiRoot {
public:
    /// Construct with panel registry.
    explicit UiRoot(PanelRegistry& registry);

    /// Render the UI (called each frame within ImGui context).
    void render();

private:
    PanelRegistry& registry_;
};

@@NS_CLOSE@@

#endif // @@NS_UPPER@@_UI_HPP
