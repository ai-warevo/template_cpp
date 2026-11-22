#include <@@NS_PATH@@/types.hpp>

#include <algorithm>

namespace @ @NS_OPEN @ @

    void
    PanelRegistry::register_panel(std::shared_ptr<IPanel> panel) {
    if (panel) {
        panels_.push_back(std::move(panel));
    }
} // namespace PanelRegistry::register_panel(std::shared_ptr<IPanel>panel)

std::shared_ptr<IPanel> PanelRegistry::get_panel(PanelId id) const {
    auto it = std::ranges::find_if(panels_, [id](const auto& p) { return p->id() == id; });
    return it != panels_.end() ? *it : nullptr;
}

const std::vector<std::shared_ptr<IPanel>>& PanelRegistry::panels() const {
    return panels_;
}

OverlayCanvas& PanelRegistry::overlay_canvas() {
    return overlay_canvas_;
}

const OverlayCanvas& PanelRegistry::overlay_canvas() const {
    return overlay_canvas_;
}

@ @NS_CLOSE @ @
