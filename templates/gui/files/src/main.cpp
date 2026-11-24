#include "gl_loader.hpp"
#include <GLFW/glfw3.h>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <cstdlib>
#include <iostream>
#include <memory>

#ifdef _WIN32
    #define GLFW_EXPOSE_NATIVE_WIN32
    #include <GLFW/glfw3native.h>
    #include <windows.h>
    #include <dwmapi.h>
    #pragma comment(lib, "dwmapi.lib")
#endif

#include <@@NS_PATH@@/ui.hpp>
#include <@@NS_PATH@@/types.hpp>
#include <@@NS_PATH@@/config.hpp>
#include "panels/general_panel.hpp"
#include "panels/overlay_demo_panel.hpp"

namespace {

void glfw_error_callback(int error, const char* description) {
    std::cerr << "GLFW Error " << error << ": " << description << "\n";
}

void set_window_icon(GLFWwindow* window) {
#ifdef _WIN32
    /* On Windows, retrieve the application icon from the executable
       and assign it to the window for title bar and taskbar display. */
    HWND hwnd = glfwGetWin32Window(window);
    if (hwnd) {
        HICON icon = LoadIconW(GetModuleHandleW(nullptr), L"IDI_ICON1");
        if (icon) {
            SendMessageW(hwnd, WM_SETICON, ICON_BIG, reinterpret_cast<LPARAM>(icon));
            SendMessageW(hwnd, WM_SETICON, ICON_SMALL, reinterpret_cast<LPARAM>(icon));
        }
    }
#else
    /* On other platforms, icon handling is platform-specific or not critical.
       GLFW will use platform defaults. */
    (void)window;
#endif
}

void update_titlebar_theme(GLFWwindow* window, bool dark_mode) {
#ifdef _WIN32
    HWND hwnd = glfwGetWin32Window(window);
    if (!hwnd) return;

    /* Set immersive dark mode */
    BOOL use_dark = dark_mode ? TRUE : FALSE;
    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &use_dark, sizeof(use_dark));

    /* Set caption color based on theme */
    COLORREF caption_color = dark_mode ? RGB(0x0A, 0x0D, 0x12) : RGB(0xFF, 0xFF, 0xFF);
    DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &caption_color, sizeof(caption_color));
#else
    (void)window;
    (void)dark_mode;
#endif
}

void setup_imgui_style(bool dark_mode) {
    /* Apply design_sense: dark tonal palette with rounded geometry. */
    if (dark_mode) {
        ImGui::StyleColorsDark();
    } else {
        ImGui::StyleColorsLight();
    }

    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 8.0f;
    style.FrameRounding = 999.0f; /* Pill-shaped buttons. */
    style.ScrollbarRounding = 999.0f;
    style.GrabRounding = 999.0f;
    style.TabRounding = 4.0f;

    if (dark_mode) {
        ImVec4* colors = style.Colors;
        colors[ImGuiCol_WindowBg] = ImVec4(0.04f, 0.05f, 0.07f, 1.00f);
        colors[ImGuiCol_ChildBg] = ImVec4(0.06f, 0.08f, 0.11f, 1.00f);
        colors[ImGuiCol_FrameBg] = ImVec4(0.09f, 0.11f, 0.17f, 1.00f);
        colors[ImGuiCol_FrameBgHovered] = ImVec4(0.12f, 0.16f, 0.21f, 1.00f);
        colors[ImGuiCol_FrameBgActive] = ImVec4(0.22f, 0.74f, 0.97f, 0.30f);
        colors[ImGuiCol_TitleBg] = ImVec4(0.02f, 0.03f, 0.05f, 1.00f);
        colors[ImGuiCol_TitleBgActive] = ImVec4(0.04f, 0.05f, 0.07f, 1.00f);
        colors[ImGuiCol_Button] = ImVec4(0.22f, 0.74f, 0.97f, 0.40f);
        colors[ImGuiCol_ButtonHovered] = ImVec4(0.22f, 0.74f, 0.97f, 0.60f);
        colors[ImGuiCol_ButtonActive] = ImVec4(0.22f, 0.74f, 0.97f, 0.80f);
        colors[ImGuiCol_Header] = ImVec4(0.22f, 0.74f, 0.97f, 0.30f);
        colors[ImGuiCol_HeaderHovered] = ImVec4(0.22f, 0.74f, 0.97f, 0.50f);
        colors[ImGuiCol_HeaderActive] = ImVec4(0.22f, 0.74f, 0.97f, 0.70f);
    }
}

} // namespace

int main() {
    glfwSetErrorCallback(glfw_error_callback);
    if (!glfwInit()) {
        std::cerr << "Failed to initialize GLFW\n";
        return EXIT_FAILURE;
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    GLFWwindow* window = glfwCreateWindow(1280, 720, "@@NAME@@ GUI", nullptr, nullptr);
    if (!window) {
        std::cerr << "Failed to create GLFW window\n";
        glfwTerminate();
        return EXIT_FAILURE;
    }

    set_window_icon(window);

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1); /* Enable vsync. */

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;

    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    @@NS@@ ::AppState app_state;
    @@NS@@ ::PanelRegistry registry;

    registry.register_panel(std::make_shared<@@NS@@ ::GeneralPanel>());
    registry.register_panel(std::make_shared<@@NS@@ ::OverlayDemoPanel>(registry.overlay_canvas()));

    @@NS@@ ::UiRoot ui_root(registry);

    setup_imgui_style(true);
    update_titlebar_theme(window, true);

#ifndef NDEBUG
    bool show_style_editor = false;
#endif

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        /* Handle F1 to toggle UI visibility */
        if (ImGui::IsKeyPressed(ImGuiKey_F1)) {
            app_state.ui_visible = !app_state.ui_visible;
        }

        /* Handle ESC quit */
        if (ImGui::IsKeyPressed(ImGuiKey_Escape)) {
            glfwSetWindowShouldClose(window, GLFW_TRUE);
        }

#ifndef NDEBUG
        /* F12 toggles style editor in debug builds only. */
        if (ImGui::IsKeyPressed(ImGuiKey_F12)) {
            show_style_editor = !show_style_editor;
        }
#endif

        /* Start ImGui frame */
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        /* Render UI only if visible (F1 to toggle) */
        if (app_state.ui_visible) {
            ui_root.render();
        }

#ifndef NDEBUG
        /* Developer-only: show ImGui style editor when toggled. */
        if (show_style_editor) {
            ImGui::Begin("Debug: Style Editor", &show_style_editor);
            ImGui::ShowStyleEditor();
            ImGui::End();
        }
#endif

        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.02f, 0.03f, 0.05f, 1.00f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    return EXIT_SUCCESS;
}
