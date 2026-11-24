#include "general_panel.hpp"

#include <imgui.h>

@@NS_OPEN@@

    GeneralPanel::GeneralPanel(AppState& state)
    : state_(state) {}

void GeneralPanel::render() {
    ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);
    if (ImGui::Begin("General Settings")) {
        ImGui::SeparatorText("Window");
        ImGui::SliderInt("Width##window", &state_.window_width, 640, 1920);
        ImGui::SliderInt("Height##window", &state_.window_height, 480, 1080);

        ImGui::SeparatorText("UI State");
        ImGui::Checkbox("UI Visible", &state_.ui_visible);
        ImGui::SliderFloat("UI Opacity", &state_.ui_opacity, 0.0f, 1.0f);

        ImGui::SeparatorText("Input");
        static char user_text_buffer[256] = {};
        ImGui::InputText("Text Input", user_text_buffer, sizeof(user_text_buffer));
        if (ImGui::Button("Update")) {
            state_.user_text = user_text_buffer;
        }
        ImGui::SameLine();
        ImGui::Text("Stored: %s", state_.user_text.c_str());

        ImGui::SeparatorText("Theme");
        ImGui::Checkbox("Dark Mode", &state_.dark_mode);
        ImGui::SliderFloat("Overlay Scale", &state_.overlay_scale, 0.5f, 2.0f);
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
