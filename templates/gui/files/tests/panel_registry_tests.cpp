#include <@@NS_PATH@@/types.hpp>
#include <catch2/catch_test_macros.hpp>
#include <memory>

namespace {

class MockPanel : public @@NS@@::IPanel {
public:
    explicit MockPanel(@@NS@@::PanelId id) : id_(id) {}

    @@NS@@::PanelId id() const override { return id_; }
    std::string name() const override { return "MockPanel"; }
    void render() override { ++render_count; }

    int render_count = 0;

private:
    @@NS@@::PanelId id_;
};

} // namespace

TEST_CASE("PanelRegistry registers and retrieves panels", "[panel_registry]") {
    @@NS@@::PanelRegistry registry;

    auto panel1 = std::make_shared<MockPanel>(@@NS@@::PanelId::General);
    auto panel2 = std::make_shared<MockPanel>(@@NS@@::PanelId::OverlayDemo);

    registry.register_panel(panel1);
    registry.register_panel(panel2);

    auto retrieved1 = registry.get_panel(@@NS@@::PanelId::General);
    auto retrieved2 = registry.get_panel(@@NS@@::PanelId::OverlayDemo);

    REQUIRE(retrieved1 != nullptr);
    REQUIRE(retrieved2 != nullptr);
    REQUIRE(retrieved1->id() == @@NS@@::PanelId::General);
    REQUIRE(retrieved2->id() == @@NS@@::PanelId::OverlayDemo);
}

TEST_CASE("PanelRegistry returns all registered panels", "[panel_registry]") {
    @@NS@@::PanelRegistry registry;

    auto panel1 = std::make_shared<MockPanel>(@@NS@@::PanelId::General);
    auto panel2 = std::make_shared<MockPanel>(@@NS@@::PanelId::OverlayDemo);

    registry.register_panel(panel1);
    registry.register_panel(panel2);

    const auto& panels = registry.panels();
    REQUIRE(panels.size() == 2);
    CHECK(panels[0]->id() == @@NS@@::PanelId::General);
    CHECK(panels[1]->id() == @@NS@@::PanelId::OverlayDemo);
}

TEST_CASE("PanelRegistry returns nullptr for unregistered panel", "[panel_registry]") {
    @@NS@@::PanelRegistry registry;

    auto panel = std::make_shared<MockPanel>(@@NS@@::PanelId::General);
    registry.register_panel(panel);

    auto not_found = registry.get_panel(@@NS@@::PanelId::OverlayDemo);
    REQUIRE(not_found == nullptr);
}
