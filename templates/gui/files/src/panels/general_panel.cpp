#include "general_panel.hpp"

#include <imgui.h>

@@NS_OPEN@@

GeneralPanel::GeneralPanel() = default;

void GeneralPanel::render() {
    ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);
    if (ImGui::Begin("General Settings")) {
        ImGui::SeparatorText("Example Panel");
        ImGui::Text("This is a template panel.");
        ImGui::Text("Extend with your app-specific UI.");

        ImGui::SeparatorText("Text Input");
        static char buffer[256] = {};
        ImGui::InputText("Enter text", buffer, sizeof(buffer));
        ImGui::Text("You entered: %s", user_text_.c_str());
        if (ImGui::Button("Update")) {
            user_text_ = buffer;
        }
    }
    ImGui::End();
}

PanelId GeneralPanel::id() const {
    return PanelId::General;
}

std::string GeneralPanel::name() const {
    return "General";
}

@@NS_CLOSE@@
