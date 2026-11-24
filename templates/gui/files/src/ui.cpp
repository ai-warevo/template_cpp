#include <@@NS_PATH@@/ui.hpp>
#include <@@NS_PATH@@/types.hpp>

#include <imgui.h>

@@NS_OPEN@@

UiRoot::UiRoot(PanelRegistry& registry)
    : registry_(registry) {}

void UiRoot::render() {
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    ImGui::SetNextWindowViewport(viewport->ID);

    ImGuiWindowFlags window_flags = ImGuiWindowFlags_NoDecoration |
                                    ImGuiWindowFlags_NoMove |
                                    ImGuiWindowFlags_NoResize |
                                    ImGuiWindowFlags_NoSavedSettings |
                                    ImGuiWindowFlags_NoBringToFrontOnFocus |
                                    ImGuiWindowFlags_NoNavFocus;

    ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));

    if (ImGui::Begin("##MainWindow", nullptr, window_flags)) {
        ImGui::PopStyleVar(3);

        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(16.0f, 16.0f));
        ImGui::PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2(12.0f, 8.0f));

        ImGui::PushFont(ImGui::GetFont());
        ImGui::Text("@@NAME@@");
        ImGui::SameLine();
        ImGui::TextDisabled("—");
        ImGui::SameLine();
        ImGui::TextDisabled("Application");
        ImGui::PopFont();

        ImGui::Separator();
        ImGui::Spacing();

        if (ImGui::BeginTabBar("MainTabs", ImGuiTabBarFlags_None)) {
            for (const auto& panel : registry_.panels()) {
                if (ImGui::BeginTabItem(panel->name().c_str())) {
                    panel->render();
                    ImGui::EndTabItem();
                }
            }
            ImGui::EndTabBar();
        }

        ImGui::Separator();
        ImGui::Spacing();
        ImGui::TextDisabled("F1: toggle UI  |  ESC: quit");
        #ifndef NDEBUG
        ImGui::TextDisabled("F12: style editor (debug only)");
        #endif

        ImGui::PopStyleVar(2);
    } else {
        ImGui::PopStyleVar(3);
    }
    ImGui::End();
}

@@NS_CLOSE@@
