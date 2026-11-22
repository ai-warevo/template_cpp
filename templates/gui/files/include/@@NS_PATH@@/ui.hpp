#pragma once

#include <memory>

@@NS_OPEN@@

class PanelRegistry;
struct AppState;

/// Root UI class that orchestrates all panels and rendering.
class UiRoot {
public:
    /// Construct with references to app state and panel registry.
    explicit UiRoot(AppState& state, PanelRegistry& registry);

    /// Render the UI (called each frame within ImGui context).
    void render();

private:
    AppState& state_;
    PanelRegistry& registry_;
};

@@NS_CLOSE@@
