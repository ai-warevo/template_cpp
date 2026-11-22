/// @file gl_loader.hpp
/// Minimal OpenGL loader wrapper for Dear ImGui backends.
/// Ensures GL functions are properly declared before ImGui uses them.

#pragma once

// On Linux/Unix, include system GL headers
#ifdef __linux__
    #define GL_GLEXT_PROTOTYPES
    #include <GL/gl.h>
    #include <GL/glext.h>
#endif

// On macOS, use system OpenGL framework
#ifdef __APPLE__
    #include <OpenGL/gl.h>
    #include <OpenGL/glext.h>
#endif

// On Windows, use glfw which provides a GL context
#ifdef _WIN32
    // GLFW will provide windows.h and wglext.h via its header
    #define GL_GLEXT_PROTOTYPES
    #include <GL/gl.h>
    #include <GL/glext.h>
#endif

#endif // GL_LOADER_HPP
