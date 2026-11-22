#include <@@NS_PATH@@/ui.hpp>
#include <@@NS_PATH@@/config.hpp>
#include <@@NS_PATH@@/types.hpp>

#include <imgui.h>

@@NS_OPEN@@

    UiRoot::UiRoot(AppState& state, PanelRegistry& registry)
    : state_(state),
      registry_(registry) {}

void UiRoot::render() {
    ImGui::SetNextWindowPos(ImVec2(10, 10), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(600, 400), ImGuiCond_FirstUseEver);

    if (ImGui::Begin("@@NAME@@ Control Panel", nullptr, ImGuiWindowFlags_NoMove)) {
        ImGui::Text("Application: @@NAME@@");
        ImGui::Separator();

        // Tabs for each panel
        if (ImGui::BeginTabBar("PanelTabs")) {
            for (const auto& panel : registry_.panels()) {
                if (ImGui::BeginTabItem(panel->name().c_str())) {
                    panel->render();
                    ImGui::EndTabItem();
                }
            }
            ImGui::EndTabBar();
        }

        ImGui::Separator();
        ImGui::TextDisabled("Press F1 to toggle UI | ESC to quit");
    }
    ImGui::End();
}

@@NS_CLOSE@@
