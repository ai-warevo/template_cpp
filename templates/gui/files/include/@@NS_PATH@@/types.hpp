#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

@@NS_OPEN@@

/// Panel identifiers for registration and lookup.
enum class PanelId : std::uint32_t {
    General = 0,
    OverlayDemo = 1,
};

/// Drawing command types for overlay canvas.
enum class DrawType : std::uint8_t {
    Line = 0,
    Circle = 1,
    Rect = 2,
};

/// Single drawing command to be rendered on the overlay canvas.
struct DrawCommand {
    DrawType type = DrawType::Line;
    float x1 = 0.0f, y1 = 0.0f;
    float x2 = 0.0f, y2 = 0.0f;
    float r = 0.0f;  // radius for circle
    std::uint32_t color = 0xFFFFFFFF;
};

/// Overlay canvas stores draw commands submitted by panels.
class OverlayCanvas {
public:
    /// Push a draw command to the queue.
    void push_command(const DrawCommand& cmd);

    /// Get all current commands.
    [[nodiscard]] const std::vector<DrawCommand>& commands() const;

    /// Clear all commands.
    void clear();

private:
    std::vector<DrawCommand> commands_;
};

/// Interface for UI panels.
class IPanel {
public:
    virtual ~IPanel() = default;

    /// Render the panel UI using ImGui. Called on each frame.
    virtual void render() = 0;

    /// Get the panel's unique identifier.
    [[nodiscard]] virtual PanelId id() const = 0;

    /// Get the panel's display name.
    [[nodiscard]] virtual std::string name() const = 0;
};

/// Registry for managing panels and the shared overlay canvas.
class PanelRegistry {
public:
    /// Register a panel.
    void register_panel(std::shared_ptr<IPanel> panel);

    /// Look up a panel by ID.
    [[nodiscard]] std::shared_ptr<IPanel> get_panel(PanelId id) const;

    /// Get all registered panels.
    [[nodiscard]] const std::vector<std::shared_ptr<IPanel>>& panels() const;

    /// Get the shared overlay canvas.
    [[nodiscard]] OverlayCanvas& overlay_canvas();
    [[nodiscard]] const OverlayCanvas& overlay_canvas() const;

private:
    std::vector<std::shared_ptr<IPanel>> panels_;
    OverlayCanvas overlay_canvas_;
};

@@NS_CLOSE@@
