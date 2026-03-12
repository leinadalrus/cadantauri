const std = @import("std");
const cadantauri = @import("cadantauri");
const ae = @import("audio/engine.zig");
const pa = @cImport({
    @cInclude("portaudio.h");
});
const libsnd = @cImport({
    @cInclude("sndfile.h");
});
const nk = @cImport({
    @cDefine("NK_IMPLEMENTATION", 1);
    @cInclude("nuklear.h");
});
const sdl = @cImport({
    @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {
    // ?NOTE(SDL_INIT_AUDIO): you only need to initialise PortAudio, not SDL Audio
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        std.debug.print("SDL_Init has encountered an error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitFailed;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow(
        "Cadantauri",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOW_RESIZABLE,
    );
    if (window == null) {
        return error.WindowCreationFailed;
    }
    defer sdl.SDL_DestroyWindow(window);

    if (pa.Pa_Initialize() != pa.paNoError) {}
    defer _ = pa.Pa_Terminate();

    var user_data: ae.PhaseAudioData = .{ .left_phase = 0.0, .right_phase = 0.0 };
    const frames_per_buffer: u32 = 256;

    const input_channels: i8 = 2;
    const output_channels: i8 = 2;

    const sample_format: u32 = pa.paFloat32;
    const sample_rate: f64 = 44100.0;

    var stream: ?*pa.PaStream = undefined;
    _ = pa.Pa_OpenDefaultStream(&stream, input_channels, output_channels, sample_format, sample_rate, frames_per_buffer, ae.PhaseAudioData.phase_audio_callback, &user_data);
    defer _ = pa.Pa_CloseStream(stream);

    _ = pa.Pa_StartStream(stream);
    defer _ = pa.Pa_StopStream(stream);
}
