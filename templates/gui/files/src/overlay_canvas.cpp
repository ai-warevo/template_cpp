#include <@@NS_PATH@@/types.hpp>

namespace @@NS_OPEN@@

    void
    OverlayCanvas::push_command(const DrawCommand& cmd) {
    commands_.push_back(cmd);
}

const std::vector<DrawCommand>& OverlayCanvas::commands() const {
    return commands_;
}

void OverlayCanvas::clear() {
    commands_.clear();
}

@@NS_CLOSE@@
