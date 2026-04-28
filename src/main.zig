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
// ? NOTE(Pub-Sub): Producer-Consumer Problem

pub fn main() !void {}

fn circle_buffer(buffer_length: u32) !void {
    const buffer: [buffer_length]u8 = {};
    const write_index = 0;
    const read_index = 0;

    const item = put(buffer, write_index, read_index, buffer_length);
    const value = get(item, buffer, write_index, read_index, buffer_length);
    std.debug.print("{x}, {x}", .{ item, value });

    const ring_buffer_data = CircleBufferData{
        write_index, 0, buffer, 0, 0,
    };
    std.debug.print("{x}", .{ring_buffer_data});
}

fn put(buffer: []u8, write_index: i8, read_index: i8, buffer_length: u32) comptime_int {
    if ((write_index + 1) % buffer_length == read_index) {
        return 0;
    }
    buffer[write_index];
    write_index = (write_index + 1) % buffer_length;

    return 1;
}

fn get(value: *const i8, buffer: []u8, write_index: i8, read_index: i8, buffer_length: u32) comptime_int {
    if (read_index == write_index) {
        return 0;
    }
    value = buffer[read_index];
    read_index = (read_index + 1) % buffer_length;

    return 1;
}

const CircleBufferData = struct {
    frame_index: c_int,
    thread_sync_flag: c_int,
    ring_buffer_data: []c_int, // previously was a type: float
    file: anyopaque,
    thread_handle: anyopaque,
};
