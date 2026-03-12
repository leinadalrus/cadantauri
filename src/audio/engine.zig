pub const std = @import("std");
pub const cadantauri = @import("cadantauri");
pub const pa = @cImport({
    @cInclude("portaudio.h");
});
pub const libsnd = @cImport({
    @cInclude("sndfile.h");
});
pub const nk = @cImport({
    @cDefine("NK_IMPLEMENTATION", 1);
    @cInclude("nuklear.h");
});
pub const sdl = @cImport({
    @cDefine("SDL_MAIN_USE_CALLBACKS", "1");
    @cInclude("SDL3/SDL.h");
});

// * Audio Engine

pub const STATE_PAUSED = 0;
pub const STATE_PLAYING = 1;
pub const STATE_STOPPING = 2;

pub const MAX_CHANNELS = 1;
pub const MAX_TRACKS = 1;
var channel_states: [MAX_CHANNELS]u8 = undefined;
var track_states: [MAX_TRACKS]u8 = undefined;

pub const AppState = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
};

// * Track Mixing

pub const AudioTrackUnit = struct {
    id: TrackID,
    name: TrackName,
    data: AudioTrackData,
    panning: AudioPanningUnit,
    volume: AudioVolumeUnit,
};

pub const AudioChannelUnit = struct {
    id: ChannelID,
    name: ChannelName,
    data: AudioChannelData,
    panning: AudioPanningUnit,
    volume: AudioVolumeUnit,
};

pub const AudioTrackData = struct {
    input_buffer: ?*const anyopaque,
    output_buffer: ?*anyopaque,
    frames_per_buffer: c_ulong,
    callback_time_info: [*c]const pa.PaStreamCallbackTimeInfo,
    callback_flags: pa.PaStreamCallbackFlags,
    user_data: ?*anyopaque,
};

pub const AudioChannelData = struct {
    input_buffer: ?*const anyopaque,
    output_buffer: ?*anyopaque,
    frames_per_buffer: c_ulong,
    callback_time_info: [*c]const pa.PaStreamCallbackTimeInfo,
    callback_flags: pa.PaStreamCallbackFlags,
    user_data: ?*anyopaque,
};

// * Basic Effects: volume and panning

pub const AudioVolumeUnit = struct {
    volume_level: f32,
};

pub const AudioPanningUnit = struct {
    panning_level: f32,
};

pub const TrackID = struct {
    id: u8,
};

pub const TrackName = struct {
    name: []const u8,
};

pub const ChannelID = struct {
    id: u8,
};

pub const ChannelName = struct {
    name: []const u8,
};

// * Real-time Audio Playback

pub const PhaseAudioData = struct {
    left_phase: f32,
    right_phase: f32,

    pub fn phase_audio_callback(
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

// * Buffer Management: playback and stack/heap buffers and data-structures
