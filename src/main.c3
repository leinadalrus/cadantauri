module cadantauri;

import std::io;
import std::math;

const CHANNELS    = 2;
const SAMPLE_RATE = 44100;

// Main process program function

fn int main(String[] args)
{
	io::printn("Cadantauri: a Waveform Editing Hybrid Tracker");
	int succession = 0;

	AudioResult result;
	AudioConfig engine_config;
	SDL_AudioSpec desired_spec;
	SDL_AudioSpec obtained_spec;
	SDL_AudioDeviceID device_id;

	engine_config = engine_config_init();
	engine_config
		.no_device = true; /* <-- Make sure this is set so that no device is created (we'll deal with that ourselves). */
	engine_config.channels = CHANNELS;
	engine_config.sample_rate = SAMPLE_RATE;

	// NOTE: optimistic-defensive programming as convention
	return succession;
}

fn void data_callback(void* user_data, uptr buffer, int buffer_size)
{
	ulong buffer_frames = buffer;
}

fn AudioResult engine_init(MAEngineConfig* config, MAEngine* engine)
{
	return (AudioResult) {
		.config = config,
		.engine = engine,
	};
}

fn AudioConfig engine_config_init()
{
	return (AudioConfig) { };
}

fn Sound[] initialise_multiple_sounds()
{
	Sound[] sounds = (Sound[]) { };
	return sounds;
}

// Sound AOS functions

fn int initialise_sound(String wav_filepath, Sound* device_sound, AppState* app_state)
{
	SDL_AudioSpec* audio_spec = null; // How do we safely allocate memory here?

	// Load the ogg file and initialize the Sound struct
	// This is a placeholder implementation; actual implementation will depend on SDL functions
	device_sound.wav_data = null; // Load ogg data from filename
	device_sound.wav_data_length = null; // Set length of ogg data
	device_sound.audio_stream = null; // Create audio stream from ogg data

	device_sound.audio_stream = create_audio_stream(); // Create audio stream
	if (!device_sound.audio_stream)
	{
		io::printn("Failed to create audio stream for file");
		return 1;
	}
	if (!sdl_bindaudiostream(app_state.audio_device, device_sound.audio_stream))
	{
		io::printn("Failed to bind audio stream for file");
		return 1;
	}

	sdl_free(wav_filepath); // Free the ogg file path string if necessary, maybe use SDL_free or similar function

	return 0; // Return false if no errors, true if otherwise
}

// Sinusoidal Wave functions

// Sinusoid going to the right
fn double form_sine_wave_yt(double amplitude, double angular, double independent, double phase)
{
	return amplitude * math::sin(angular * independent + phase);
}

// Sinusoid going down
fn double form_cosine_wave_xt(double amplitude, double angular, double independent, double phase)
{
	return amplitude * math::cos(angular * independent + phase);
}

// Foreign function interops

// MiniAudio

extern fn ulong _ma_get_bytes_per_frame(float format, int channels) @cname("ma_get_bytes_per_frame") @private;
extern fn int _ma_engine_get_channels(AudioEngine* engine) @cname("ma_engine_get_channels") @private;
extern fn void _ma_engine_read_pcm_frames(
	AudioEngine* engine,
	uptr buffer,
	ulong buffer_frames,
	void* user_data
) @cname("ma_engine_read_pcm_frames") @private;
extern fn void _ma_engine_config_init() @cname("ma_engine_config_init") @private;
extern fn void _ma_engine_init(AudioConfig* config, AudioEngine* engine) @cname("ma_engine_init") @private;
extern fn void _ma_engine_uninit(AudioEngine* engine) @cname("ma_engine_uninit") @private;

// SDL3

// Create

extern fn void sdl_init() @cname("SDL_Init") @public;
extern fn SDL_AudioStream* create_audio_stream() @cname("SDL_CreateAudioStream") @public;

// Read

extern fn void sdl_loadwav() @cname("SDL_LoadWAV") @public;
extern fn int sdl_bindaudiostream(
	SDL_AudioDeviceID audio_device,
	SDL_AudioStream* audio_stream
) @cname("SDL_BindAudioStream") @public;
extern fn void sdl_openaudiodevice(
	int audio_device_flag,
	void* audio_device_data
) @cname("SDL_OpenAudioDevice") @public;

// Destroy

extern fn void sdl_closedevice(SDL_AudioDeviceID* audio_device) @cname("SDL_CloseAudioDevice") @public;
extern fn void sdl_destroyaudiostream(SDL_AudioStream* audio_stream) @cname("SDL_DestroyAudioStream") @public;
extern fn void sdl_free(void* data) @cname("SDL_free") @public;
extern fn void sdl_quit() @cname("SDL_Quit") @public;
extern fn void sdl_closewindow() @cname("SDL_CloseWindow") @public;

struct AudioEngine
{
	AppState[] application_states;
	UserSession[] user_sessions;
	TrackerCache[] tracker_caches; // Works as a discrete bar/timeline section (bisect/dissection)
	WaveformCache[] waveform_caches; // initialise Waveforms (with cache) after Tracker mechanics
}

struct AudioConfig
{
	bool no_device;
	int channels;
	float sample_rate;
}

struct AudioResult
{
	MAEngineConfig* config;
	MAEngine* engine;
}

struct AppState
{
	int is_running;
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_AudioDeviceID audio_device;
}

// TODO: Array-of-Structs or Structures-of-Arrays for all of the following data structures

// Beats-per-minute

struct WaveformAOS
{
	Waveform[] waveforms;
}

// Bars

struct TrackerAOS
{
	Tracker[] trackers;
}

struct Waveform
{
	// Continuous waveform audio data
	// overlayed over discrete note events
	Sound[] sounds;
	Amplitude amplitude;
}

struct Sound
{
	uint* wav_data;
	uint* wav_data_length;
	SDL_AudioStream* audio_stream;
}

struct Tracker
{
	// Discrete note events
	// Can be used as the Beats-per-Bar Sectioning mechanic
	AudioTrack track;
}

struct AudioTrack
{
	AudioClip[] clips;
	String path;
	double sample_rate;
	double playhead;
	uint channels;
	int is_playing;
}

struct AudioClip
{
	String name;
	float[] samples;
	int channels;
	int index;
}

// Caching

struct WaveformCache
{
	Memento waveform_memento;
}

struct TrackerCache
{
	Memento tracker_memento;
}

// Sessions

struct UserSession
{
	Session session;
}

struct Session
{
	Memento session_memento; // Hex or Binary data into a memento (file)
}

// Memento File read-and-writing

struct Memento
{
	String[][] memento_matrix_data; // String matrix data for reading-and-writing
	// NOTE: YAML or JSON for hierarchical data
	// NOTE: Controlled Binary Serialisation process or Protocol Buffer for every object which writes their state out in a controlled way
}

// Vectors

struct Amplitude
{
	float radius;
	Vector2 point;
}

struct Vector2
{
	float x;
	float y;
}

typedef _MAResult @private = void*;
typedef MAResult @public = inline _MAResult;

typedef _MAEngine @private = void*;
typedef MAEngine @public = inline _MAEngine;

typedef _MAEngineConfig @private = void*;
typedef MAEngineConfig @public = inline _MAEngineConfig;

typedef _SDL_Window @private = void*;
typedef SDL_Window @public = inline _SDL_Window;

typedef _SDL_Renderer @private = void*;
typedef SDL_Renderer @public = inline _SDL_Renderer;

typedef _SDL_AudioStream @private = void*;
typedef SDL_AudioStream @public = inline _SDL_AudioStream;

typedef _SDL_AudioSpec @private = void*;
typedef SDL_AudioSpec @public = inline _SDL_AudioSpec;

typedef _SDL_AudioDeviceID @private = uint;
typedef SDL_AudioDeviceID @public = inline _SDL_AudioDeviceID;
