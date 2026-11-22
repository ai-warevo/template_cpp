#include <@@NS_PATH@@/types.hpp>
#include <catch2/catch_test_macros.hpp>

namespace {
class MockPanel : public @@NS_OPEN@@IPanel {
public:
    explicit MockPanel(@@NS_PATH@@ ::PanelId id)
        : id_(id) {}

    @@NS_PATH@@ ::PanelId id() const override {
        return id_;
    }
    const char* name() const override { return "MockPanel"; }
    void render(@@NS_PATH@@ ::AppState&) override { ++render_count; }

    int render_count = 0;

private:
    @@NS_PATH@@ ::PanelId id_;
};
} // namespace

TEST_CASE("PanelRegistry registers and looks up panels", "[panel_registry]") {
    @@NS_OPEN@@PanelRegistry registry;

    auto panel1 = std::make_unique<MockPanel>(@@NS_PATH@@ ::PanelId::General);
    auto panel2 = std::make_unique<MockPanel>(@@NS_PATH@@ ::PanelId::OverlayDemo);

    auto* p1_ptr = panel1.get();
    auto* p2_ptr = panel2.get();

    registry.register_panel(std::move(panel1));
    registry.register_panel(std::move(panel2));

    // Lookup by ID
    auto* found1 = registry.find(@@NS_PATH@@ ::PanelId::General);
    auto* found2 = registry.find(@@NS_PATH@@ ::PanelId::OverlayDemo);

    REQUIRE(found1 == p1_ptr);
    REQUIRE(found2 == p2_ptr);
}

TEST_CASE("PanelRegistry returns all panels", "[panel_registry]") {
    @@NS_OPEN@@PanelRegistry registry;

    registry.register_panel(std::make_unique<MockPanel>(@@NS_PATH@@ ::PanelId::General));
    registry.register_panel(std::make_unique<MockPanel>(@@NS_PATH@@ ::PanelId::OverlayDemo));

    const auto& panels = registry.all();

    REQUIRE(panels.size() == 2);
}

TEST_CASE("PanelRegistry find returns nullptr for missing panel", "[panel_registry]") {
    @@NS_OPEN@@PanelRegistry registry;

    auto* not_found = registry.find(@@NS_PATH@@ ::PanelId::General);

    REQUIRE(not_found == nullptr);
}
