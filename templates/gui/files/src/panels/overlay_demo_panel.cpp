#include "overlay_demo_panel.hpp"

#include <imgui.h>

namespace @ @NS_OPEN @ @

    OverlayDemoPanel::OverlayDemoPanel(OverlayCanvas& canvas)
    : canvas_(canvas) {}

void OverlayDemoPanel::render() {
    ImGui::SetNextWindowSize(ImVec2(350, 250), ImGuiCond_FirstUseEver);
    if (ImGui::Begin("Overlay Demo")) {
        ImGui::Text("Draw commands to the overlay canvas:");

        if (ImGui::Button("Draw Line", ImVec2(150, 0))) {
            DrawCommand cmd;
            cmd.type = DrawType::Line;
            cmd.x1 = 100.0f;
            cmd.y1 = 100.0f;
            cmd.x2 = 300.0f;
            cmd.y2 = 200.0f;
            cmd.color = 0xFF38BDF8; // Cyan accent
            canvas_.push_command(cmd);
        }

        if (ImGui::Button("Draw Circle", ImVec2(150, 0))) {
            DrawCommand cmd;
            cmd.type = DrawType::Circle;
            cmd.x1 = 400.0f;
            cmd.y1 = 300.0f;
            cmd.r = 50.0f;
            cmd.color = 0xFF6EE7B7; // Emerald accent
            canvas_.push_command(cmd);
        }

        if (ImGui::Button("Draw Rectangle", ImVec2(150, 0))) {
            DrawCommand cmd;
            cmd.type = DrawType::Rect;
            cmd.x1 = 500.0f;
            cmd.y1 = 150.0f;
            cmd.x2 = 600.0f;
            cmd.y2 = 250.0f;
            cmd.color = 0xFFE9A568; // Amber accent
            canvas_.push_command(cmd);
        }

        ImGui::Separator();

        if (ImGui::Button("Clear Canvas", ImVec2(150, 0))) {
            canvas_.clear();
        }

        ImGui::SameLine();
        ImGui::Text("Commands: %zu", canvas_.commands().size());
    }
    ImGui::End();
}

PanelId OverlayDemoPanel::id() const {
    return PanelId::OverlayDemo;
}

std::string OverlayDemoPanel::name() const {
    return "Overlay Demo";
}

@ @NS_CLOSE @ @
