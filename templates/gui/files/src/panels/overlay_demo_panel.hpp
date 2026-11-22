#pragma once

#include <@@NS_PATH@@/types.hpp>

namespace @@NS_OPEN@@

/// Overlay demo panel that draws shapes to the overlay canvas.
class OverlayDemoPanel final : public IPanel {
public:
    explicit OverlayDemoPanel(OverlayCanvas& canvas);

    void render() override;
    [[nodiscard]] PanelId id() const override;
    [[nodiscard]] std::string name() const override;

private:
    OverlayCanvas& canvas_;
};

@@NS_CLOSE@@
