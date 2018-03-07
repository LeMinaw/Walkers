// This file is initially part of PackageCompiler.

// Standard headers
#include <string.h>
#include <stdint.h>

// Julia headers (for initialization and gc commands)
#include "uv.h"
#include "julia.h"

#ifdef JULIA_DEFINE_FAST_TLS // only available in Julia v0.7 and above
    JULIA_DEFINE_FAST_TLS()
#endif

// Declare C prototype of a function defined in Julia
extern int julia_main();

// main function (windows UTF16 -> UTF8 argument conversion code copied from julia's ui/repl.c)
int main(int argc, char *argv[]) {
    int retcode;
    uv_setup_args(argc, argv); // no-op on Windows

    // init
    libsupport_init();
    // jl_options.compile_enabled = JL_OPTIONS_COMPILE_OFF;
    // JULIAC_PROGRAM_LIBNAME defined on command-line for compilation (walkers.dll)
    jl_options.image_file = JULIAC_PROGRAM_LIBNAME;
    julia_init(JL_IMAGE_JULIA_HOME);

    // main call
    retcode = julia_main();
    JL_GC_POP();
    jl_atexit_hook(retcode);
    return retcode;
}
