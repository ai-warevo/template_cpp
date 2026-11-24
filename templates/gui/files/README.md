# @@NAME@@ GUI Application

**Modern C++23 desktop GUI application with ImGui and GLFW**

Generated from [template_cpp](https://github.com/ai-warevo/template_cpp) gui template.

---

## Architecture

**Three-layer design:**

1. **Core** (pure C++23, no ImGui)
   - Business logic, data types
   - Testable without GUI
   - Zero ImGui dependency

2. **UI** (ImGui layer)
   - Panel-based architecture
   - Fullscreen tab bar orchestration
   - Reusable panel components

3. **App** (GLFW/OpenGL host)
   - Window creation and lifecycle
   - Platform-specific setup (Windows: DWM theming, icon loading)
   - Event loop

---

## Features

✅ **Ready to extend:**
- **Panel registry system** — Dynamically register and manage UI panels
- **Overlay canvas** — Draw primitives and render commands
- **Platform abstraction** — Windows/POSIX conditional compilation
- **Debug mode** — F12 toggles ImGui style editor (Debug builds only)
- **Console hiding** — Automatic on Windows Release builds
- **Docking** — Full ImGui docking enabled

---

## Build

**Requirements:**
- C++23 compiler (GCC 13+, Clang 16+, MSVC 19.36+)
- CMake 3.23+
- OpenGL, GLFW, Dear ImGui (via FetchContent)

**Linux:**
```bash
cmake --preset dev
cmake --build --preset dev
./build/Debug/@@NAME@@_app
```

**Windows:**
```cmd
cmake --preset dev
cmake --build --preset dev --config Debug
.\build\Debug\@@NAME@@_app.exe
```

**Release (optimized, console hidden on Windows):**
```bash
cmake --preset release
cmake --build --preset release
```

**Tests:**
```bash
ctest --preset dev
ctest --preset release
```

---

## Project Structure

```
@@NAME@@/
├── CMakeLists.txt              Main build config
├── include/@@NS_PATH@@/
│   ├── ui.hpp                  UiRoot class
│   ├── types.hpp               IPanel, PanelRegistry, OverlayCanvas
│   └── config.hpp              Configuration persistence
├── src/
│   ├── main.cpp                GLFW host, platform setup
│   ├── ui.cpp                  UiRoot::render fullscreen tab bar
│   ├── config.cpp              AppState load/save
│   ├── panel_registry.cpp      Registry implementation
│   ├── overlay_canvas.cpp      Canvas implementation
│   └── panels/
│       ├── general_panel.cpp   Template example panel
│       └── overlay_demo_panel.cpp
├── tests/
│   ├── CMakeLists.txt
│   └── *_tests.cpp             Unit tests (Catch2 v3)
└── product.ico                 Application icon (Windows)
```

---

## Extending with Panels

Create a new panel by implementing `IPanel`:

```cpp
// include/@@NS_PATH@@/ui/panels/my_panel.hpp
class MyPanel final : public IPanel {
public:
    void render() override;
    [[nodiscard]] PanelId id() const override;
    [[nodiscard]] std::string name() const override;
};

// src/panels/my_panel.cpp
void MyPanel::render() {
    ImGui::Begin("My Panel");
    ImGui::Text("Hello from my panel");
    ImGui::End();
}
```

Register in `main.cpp`:
```cpp
registry.register_panel(std::make_shared<@@NS@@ ::MyPanel>());
```

---

## Debug Features

**F12 in Debug builds:** Toggle ImGui style editor for real-time UI tweaking
- Completely compiled out in Release (zero overhead)
- Access ImGui's native `ShowStyleEditor()`

---

## Windows-Specific

**Icon loading:**
- Application icon from executable (`product.ico`)
- Automatic title bar + taskbar display

**Title bar theming:**
- Dark mode support via DWM (Windows 10+)
- Dynamic caption color updates

**Console hiding:**
- Release builds: no console window
- Debug builds: console available from CLI

---

## License

MIT. See LICENSE file.
