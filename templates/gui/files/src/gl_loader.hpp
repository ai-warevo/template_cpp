/// @file gl_loader.hpp
/// Minimal OpenGL loader wrapper for Dear ImGui backends.
/// Ensures GL functions are properly declared before ImGui uses them.

#ifndef GL_LOADER_HPP
#define GL_LOADER_HPP

/* Windows: GLFW provides bundled GL headers. Ensure windows.h is included first
   to avoid macro conflicts like NOMINMAX and MIN/MAX issues. */
#ifdef _WIN32
    #ifndef WIN32_LEAN_AND_MEAN
    #define WIN32_LEAN_AND_MEAN
    #endif
    #include <windows.h>
#endif

/* Linux/Unix: Use system GL headers with extension prototypes enabled. */
#ifdef __linux__
    #define GL_GLEXT_PROTOTYPES
    #include <GL/gl.h>
    #include <GL/glext.h>
#endif

/* macOS: Use system OpenGL framework. */
#ifdef __APPLE__
    #include <OpenGL/gl.h>
    #include <OpenGL/glext.h>
#endif

#endif // GL_LOADER_HPP
