#ifndef _WIN32

/// Constructor function for the overlay shared library on POSIX systems.
__attribute__((constructor)) static void overlay_init() {
}

/// Destructor function for the overlay shared library on POSIX systems.
__attribute__((destructor)) static void overlay_cleanup() {
}

#endif // !_WIN32
