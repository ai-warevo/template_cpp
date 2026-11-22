#include <@@NS_PATH@@/config.hpp>

#include <fstream>
#include <sstream>
#include <string_view>

namespace @@NS_OPEN@@

    namespace {

    constexpr std::string_view kWindowWidth = "window_width";
    constexpr std::string_view kWindowHeight = "window_height";
    constexpr std::string_view kUiVisible = "ui_visible";
    constexpr std::string_view kUiOpacity = "ui_opacity";
    constexpr std::string_view kUserText = "user_text";
    constexpr std::string_view kDarkMode = "dark_mode";
    constexpr std::string_view kOverlayScale = "overlay_scale";

    bool parse_int(const std::string& value, int& out) {
        try {
            out = std::stoi(value);
            return true;
        } catch (...) {
            return false;
        }
    }

    bool parse_float(const std::string& value, float& out) {
        try {
            out = std::stof(value);
            return true;
        } catch (...) {
            return false;
        }
    }

    bool parse_bool(const std::string& value, bool& out) {
        if (value == "true" || value == "1") {
            out = true;
            return true;
        }
        if (value == "false" || value == "0") {
            out = false;
            return true;
        }
        return false;
    }

} // namespace @@NS_OPEN@@ namespace

bool Config::save(const std::string& path, const AppState& state) {
    std::ofstream file(path);
    if (!file) {
        return false;
    }

    file << kWindowWidth << "=" << state.window_width << "\n";
    file << kWindowHeight << "=" << state.window_height << "\n";
    file << kUiVisible << "=" << (state.ui_visible ? "true" : "false") << "\n";
    file << kUiOpacity << "=" << state.ui_opacity << "\n";
    file << kUserText << "=" << state.user_text << "\n";
    file << kDarkMode << "=" << (state.dark_mode ? "true" : "false") << "\n";
    file << kOverlayScale << "=" << state.overlay_scale << "\n";

    return file.good();
}

bool Config::load(const std::string& path, AppState& state) {
    std::ifstream file(path);
    if (!file) {
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        if (line.empty() || line[0] == '#') {
            continue;
        }

        const auto eq_pos = line.find('=');
        if (eq_pos == std::string::npos) {
            continue;
        }

        const auto key = line.substr(0, eq_pos);
        const auto value = line.substr(eq_pos + 1);

        if (key == kWindowWidth) {
            parse_int(value, state.window_width);
        } else if (key == kWindowHeight) {
            parse_int(value, state.window_height);
        } else if (key == kUiVisible) {
            parse_bool(value, state.ui_visible);
        } else if (key == kUiOpacity) {
            parse_float(value, state.ui_opacity);
        } else if (key == kUserText) {
            state.user_text = value;
        } else if (key == kDarkMode) {
            parse_bool(value, state.dark_mode);
        } else if (key == kOverlayScale) {
            parse_float(value, state.overlay_scale);
        }
    }

    return true;
}

@@NS_CLOSE@@
