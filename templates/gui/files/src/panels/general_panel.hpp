#pragma once

#include <@@NS_PATH@@/types.hpp>
#include <@@NS_PATH@@/config.hpp>

#include <string>

namespace @@NS_OPEN@@

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
