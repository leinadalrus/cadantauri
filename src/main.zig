const std = @import("std");
const cadantauri = @import("cadantauri");
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

    var user_data: PhaseAudioData = .{ .left_phase = 0.0, .right_phase = 0.0 };
    const frames_per_buffer: u32 = 256;

    const input_channels: i8 = 2;
    const output_channels: i8 = 2;

    const sample_format: u32 = pa.paFloat32;
    const sample_rate: f64 = 44100.0;

    var stream: ?*pa.PaStream = undefined;
    _ = pa.Pa_OpenDefaultStream(&stream, input_channels, output_channels, sample_format, sample_rate, frames_per_buffer, PhaseAudioData.phase_audio_callback, &user_data);
    defer _ = pa.Pa_CloseStream(stream);

    _ = pa.Pa_StartStream(stream);
    defer _ = pa.Pa_StopStream(stream);
}

const STATE_PAUSED = 0;
const STATE_PLAYING = 1;
const STATE_STOPPING = 2;

const MAX_CHANNELS = 1;
const MAX_TRACKS = 1;
var channel_states: [MAX_CHANNELS]u8 = undefined;
var track_states: [MAX_TRACKS]u8 = undefined;

const AppState = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
};

// * Track Mixing

const AudioTrackUnit = struct {
    id: TrackID,
    name: TrackName,
    data: AudioTrackData,
    panning: AudioPanningUnit,
    volume: AudioVolumeUnit,
};

const AudioChannelUnit = struct {
    id: ChannelID,
    name: ChannelName,
    data: AudioChannelData,
    panning: AudioPanningUnit,
    volume: AudioVolumeUnit,
};

const AudioTrackData = struct {
    input_buffer: ?*const anyopaque,
    output_buffer: ?*anyopaque,
    frames_per_buffer: c_ulong,
    callback_time_info: [*c]const pa.PaStreamCallbackTimeInfo,
    callback_flags: pa.PaStreamCallbackFlags,
    user_data: ?*anyopaque,
};

const AudioChannelData = struct {
    input_buffer: ?*const anyopaque,
    output_buffer: ?*anyopaque,
    frames_per_buffer: c_ulong,
    callback_time_info: [*c]const pa.PaStreamCallbackTimeInfo,
    callback_flags: pa.PaStreamCallbackFlags,
    user_data: ?*anyopaque,
};

const AudioVolumeUnit = struct {
    volume_level: f32,
};

const AudioPanningUnit = struct {
    panning_level: f32,
};

const TrackID = struct {
    id: u8,
};

const TrackName = struct {
    name: []const u8,
};

const ChannelID = struct {
    id: u8,
};

const ChannelName = struct {
    name: []const u8,
};

// * Buffer Management: playback and stack/heap buffers and data-structures

const PhaseAudioData = struct {
    left_phase: f32,
    right_phase: f32,

    fn phase_audio_callback(
        input_buffer: ?*const anyopaque,
        output_buffer: ?*anyopaque,
        frames_per_buffer: c_ulong,
        callback_time_info: [*c]const pa.PaStreamCallbackTimeInfo,
        callback_flags: pa.PaStreamCallbackFlags,
        user_data: ?*anyopaque,
    ) callconv(.winapi) c_int {
        _ = input_buffer;
        _ = callback_time_info;
        _ = callback_flags;

        const self: *PhaseAudioData = @ptrCast(@alignCast((user_data)));
        const outputs: [*]f32 = @ptrCast(@alignCast(output_buffer));

        var i: usize = 0;
        while (i < frames_per_buffer) : (i += 1) {
            outputs[i * 2] = self.left_phase;
            outputs[i * 2 + 1] = self.right_phase;

            self.left_phase += 0.01;
            if (self.left_phase >= 1.0) self.left_phase -= 2.0;

            self.right_phase += 0.03;
            if (self.right_phase >= 1.0) self.right_phase -= 2.0;
        }

        return pa.paContinue;
    }
};
