#include <@@NS_PATH@@/@@NAME_ID@@.hpp>

#include "gl_loader.hpp"
#include <GLFW/glfw3.h>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <cstdlib>
#include <iostream>
#include <memory>

// Forward declarations for panels
@@NS_OPEN@@class GeneralPanel;
class OverlayDemoPanel;
@@NS_CLOSE@@

    namespace {
    void glfw_error_callback(int error, const char* description) {
        std::cerr << "GLFW Error " << error << ": " << description << "\n";
    }

    void setup_imgui_style(bool dark_mode) {
        if (dark_mode) {
            ImGui::StyleColorsDark();
        } else {
            ImGui::StyleColorsLight();
        }

        // Apply design_sense: dark tonal palette with rounded geometry
        ImGuiStyle& style = ImGui::GetStyle();
        style.WindowRounding = 8.0f;
        style.FrameRounding = 999.0f; // Pill-shaped buttons
        style.ScrollbarRounding = 999.0f;
        style.GrabRounding = 999.0f;
        style.TabRounding = 4.0f;

        if (dark_mode) {
            ImVec4* colors = style.Colors;
            colors[ImGuiCol_WindowBg] = ImVec4(0.04f, 0.05f, 0.07f, 1.00f);       // #0A0D12
            colors[ImGuiCol_ChildBg] = ImVec4(0.06f, 0.08f, 0.11f, 1.00f);        // #0F131C
            colors[ImGuiCol_FrameBg] = ImVec4(0.09f, 0.11f, 0.17f, 1.00f);        // #161D2B
            colors[ImGuiCol_FrameBgHovered] = ImVec4(0.12f, 0.16f, 0.21f, 1.00f); // #1E2636
            colors[ImGuiCol_FrameBgActive] = ImVec4(0.22f, 0.74f, 0.97f, 0.30f);  // Accent #38BDF8
            colors[ImGuiCol_TitleBg] = ImVec4(0.02f, 0.03f, 0.05f, 1.00f);        // #05070C
            colors[ImGuiCol_TitleBgActive] = ImVec4(0.04f, 0.05f, 0.07f, 1.00f);  // #0A0D12
            colors[ImGuiCol_Button] = ImVec4(0.22f, 0.74f, 0.97f, 0.40f);         // Accent
            colors[ImGuiCol_ButtonHovered] = ImVec4(0.22f, 0.74f, 0.97f, 0.60f);
            colors[ImGuiCol_ButtonActive] = ImVec4(0.22f, 0.74f, 0.97f, 0.80f);
            colors[ImGuiCol_Header] = ImVec4(0.22f, 0.74f, 0.97f, 0.30f);
            colors[ImGuiCol_HeaderHovered] = ImVec4(0.22f, 0.74f, 0.97f, 0.50f);
            colors[ImGuiCol_HeaderActive] = ImVec4(0.22f, 0.74f, 0.97f, 0.70f);
        }
    }

} // namespace

int main() {
    // Initialize GLFW
    glfwSetErrorCallback(glfw_error_callback);
    if (!glfwInit()) {
        std::cerr << "Failed to initialize GLFW\n";
        return EXIT_FAILURE;
    }

    // OpenGL 3.3 Core Profile
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    // Create window
    GLFWwindow* window = glfwCreateWindow(1280, 720, "@@NAME@@ GUI", nullptr, nullptr);
    if (!window) {
        std::cerr << "Failed to create GLFW window\n";
        glfwTerminate();
        return EXIT_FAILURE;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1); // Enable vsync

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;

    // Setup Platform/Renderer backends
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    // Application state and registry
    @@NS@@ ::AppState app_state;
    @@NS@@ ::PanelRegistry registry;

    // Register panels (forward-declared, defined in src/panels/)
    // Note: Panel implementations include their own headers
    registry.register_panel(std::make_shared<@@NS@@ ::GeneralPanel>(app_state));
    registry.register_panel(std::make_shared<@@NS@@ ::OverlayDemoPanel>(registry.overlay_canvas()));

    // UI root
    @@NS@@ ::UiRoot ui_root(app_state, registry);

    // Setup initial style
    setup_imgui_style(app_state.dark_mode);

    // Main loop
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        // Handle F1 toggle
        if (ImGui::IsKeyPressed(ImGuiKey_F1)) {
            app_state.ui_visible = !app_state.ui_visible;
        }

        // Handle ESC quit
        if (ImGui::IsKeyPressed(ImGuiKey_Escape)) {
            glfwSetWindowShouldClose(window, GLFW_TRUE);
        }

        // Start ImGui frame
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // Render UI if visible
        if (app_state.ui_visible) {
            ui_root.render();
        }

        // Rendering
        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.02f, 0.03f, 0.05f, 1.00f); // #05070C
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    // Cleanup
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    return EXIT_SUCCESS;
}
