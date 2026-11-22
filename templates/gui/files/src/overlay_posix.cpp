#ifndef _WIN32

/// Constructor function for the overlay shared library on POSIX systems.
__attribute__((constructor)) static void overlay_init() {
    // Initialization logic when the shared library is loaded
}

/// Destructor function for the overlay shared library on POSIX systems.
__attribute__((destructor)) static void overlay_cleanup() {
    // Cleanup logic when the shared library is unloaded
}

#endif // !_WIN32
