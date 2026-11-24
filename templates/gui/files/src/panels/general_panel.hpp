#ifndef @@NS_UPPER@@_GENERAL_PANEL_HPP
#define @@NS_UPPER@@_GENERAL_PANEL_HPP

#include <@@NS_PATH@@/types.hpp>

#include <string>

@@NS_OPEN@@

/// General settings panel with ImGui controls.
class GeneralPanel final : public IPanel {
public:
    GeneralPanel();

    void render() override;
    [[nodiscard]] PanelId id() const override;
    [[nodiscard]] std::string name() const override;

private:
    std::string user_text_;
};

@@NS_CLOSE@@

#endif // @@NS_UPPER@@_GENERAL_PANEL_HPP
