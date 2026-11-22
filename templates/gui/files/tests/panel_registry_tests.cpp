#include <@@NS_PATH@@/types.hpp>
#include <catch2/catch_test_macros.hpp>

namespace {
class MockPanel : public @@NS@@::IPanel {
public:
    explicit MockPanel(@@NS@@::PanelId id)
        : id_(id) {}

    @@NS@@::PanelId id() const override {
        return id_;
    }
    const char* name() const override { return "MockPanel"; }
    void render(@@NS@@::AppState&) override { ++render_count; }

    int render_count = 0;

private:
    @@NS@@::PanelId id_;
};
} // namespace

TEST_CASE("PanelRegistry registers and looks up panels", "[panel_registry]") {
    @@NS@@::PanelRegistry registry;

    auto panel1 = std::make_unique<MockPanel>(@@NS@@::PanelId::General);
    auto panel2 = std::make_unique<MockPanel>(@@NS@@::PanelId::OverlayDemo);

    auto* p1_ptr = panel1.get();
    auto* p2_ptr = panel2.get();

    registry.register_panel(std::move(panel1));
    registry.register_panel(std::move(panel2));

    // Lookup by ID
    auto* found1 = registry.find(@@NS@@::PanelId::General);
    auto* found2 = registry.find(@@NS@@::PanelId::OverlayDemo);

    REQUIRE(found1 == p1_ptr);
    REQUIRE(found2 == p2_ptr);
}

TEST_CASE("PanelRegistry returns all panels", "[panel_registry]") {
    @@NS@@::PanelRegistry registry;

    registry.register_panel(std::make_unique<MockPanel>(@@NS@@::PanelId::General));
    registry.register_panel(std::make_unique<MockPanel>(@@NS@@::PanelId::OverlayDemo));

    const auto& panels = registry.all();

    REQUIRE(panels.size() == 2);
}

TEST_CASE("PanelRegistry find returns nullptr for missing panel", "[panel_registry]") {
    @@NS@@::PanelRegistry registry;

    auto* not_found = registry.find(@@NS@@::PanelId::General);

    REQUIRE(not_found == nullptr);
}
