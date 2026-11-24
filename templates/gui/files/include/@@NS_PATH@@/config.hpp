#pragma once

#include <string>

@@NS_OPEN@@

/// Application state and configuration (pure C++23, zero imgui.h or OS headers).
struct AppState {
    int window_width = 1280;
    int window_height = 720;
    bool ui_visible = true;
    float ui_opacity = 1.0f;
    std::string user_text;
    bool dark_mode = false;
    float overlay_scale = 1.0f;

    /* Defaulted equality for testing. */
    bool operator==(const AppState& other) const = default;
};

/// Configuration persistence (load/save via standard C++23 without external deps).
class Config {
public:
    /// Save application state to a file (simple text format: key=value lines).
    static bool save(const std::string& path, const AppState& state);

    /// Load application state from a file.
    static bool load(const std::string& path, AppState& state);
};

@@NS_CLOSE@@
