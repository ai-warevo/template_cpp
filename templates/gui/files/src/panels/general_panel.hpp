#ifndef @@NS_UPPER@@_GENERAL_PANEL_HPP
#define @@NS_UPPER@@_GENERAL_PANEL_HPP

#include <@@NS_PATH@@/types.hpp>
#include <@@NS_PATH@@/config.hpp>

#include <string>

@@NS_OPEN@@

/// General settings panel with ImGui controls.
class GeneralPanel final : public IPanel {
public:
    explicit GeneralPanel(AppState& state);

    void render() override;
    [[nodiscard]] PanelId id() const override;
    [[nodiscard]] std::string name() const override;

private:
    AppState& state_;
};

@@NS_CLOSE@@

#endif // @@NS_UPPER@@_GENERAL_PANEL_HPP
