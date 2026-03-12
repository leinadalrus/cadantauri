const std = @import("std");
const cadantauri = @import("cadantauri");
const nk = @cImport({
    @cDefine("NK_IMPLEMENTATION", 1);
    @cInclude("nuklear.h");
});
const sdl = @cImport({
    @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
    @cInclude("SDL3/SDL.h");
});
