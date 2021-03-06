module nanogui.sdlbackend;

import std.algorithm: map;
import std.array: array;
import std.exception: enforce;
import std.file: thisExePath;
import std.path: dirName, buildPath;
import std.range: iota;
import std.datetime : Clock;

import std.experimental.logger: Logger, NullLogger, FileLogger, globalLogLevel, LogLevel;

import gfm.math: mat4f, vec3f, vec4f;
import gfm.opengl: OpenGL;
import gfm.sdl2: SDL2, SDL2Window, SDL_Event;

import arsd.nanovega : NVGContext, nvgCreateContext, kill, NVGContextFlag;
import nanogui.screen : Screen;
import nanogui.theme : Theme;
import nanogui.common : Vector2i, MouseButton, MouseAction;

class SdlBackend
{
	this(int w, int h, string title)
	{
		import gfm.sdl2;

		this.width = w;
		this.height = h;

		// create a logger
		import std.stdio : stdout;
		_log = new FileLogger(stdout);

		// load dynamic libraries
		_sdl2 = new SDL2(_log, SharedLibVersion(2, 0, 0));
		_gl = new OpenGL(_log);
		globalLogLevel = LogLevel.error;

		// You have to initialize each SDL subsystem you want by hand
		_sdl2.subSystemInit(SDL_INIT_VIDEO);
		_sdl2.subSystemInit(SDL_INIT_EVENTS);

		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

		// create an OpenGL-enabled SDL window
		window = new SDL2Window(_sdl2,
								SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
								width, height,
								SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);

		window.setTitle(title);
		
		import derelict.opengl3.gl3 : GLVersion;
		// reload OpenGL now that a context exists
		_gl.reload(GLVersion.GL30, GLVersion.HighestSupported);

		// redirect OpenGL output to our Logger
		_gl.redirectDebugOutput();

		nvg = nvgCreateContext(NVGContextFlag.Debug);
		enforce(nvg !is null, "cannot initialize NanoGui");

		screen = new Screen(width, height, Clock.currTime.stdTime);
		screen.theme = new Theme(nvg);
	}

	~this()
	{
		nvg.kill();
		_gl.destroy();
		window.destroy();
		_sdl2.destroy();
	}

	auto run()
	{
		import gfm.sdl2: SDL_GetTicks, SDL_QUIT, SDL_KEYDOWN, SDL_KEYDOWN, SDL_KEYUP, SDL_MOUSEBUTTONDOWN,
			SDL_MOUSEBUTTONUP, SDL_MOUSEMOTION, SDL_MOUSEWHEEL, SDLK_ESCAPE, SDL_TEXTINPUT, SDL_TEXTEDITING,
			SDL_StartTextInput;

		onVisibleForTheFirstTime();

		SDL_StartTextInput();

		while(!_sdl2.keyboard.isPressed(SDLK_ESCAPE)) 
		{
			SDL_Event event;
			while(_sdl2.pollEvent(&event))
			{
				switch(event.type)
				{
					case SDL_QUIT:            return;
					case SDL_KEYDOWN:         onKeyDown(event);
					break;
					case SDL_KEYUP:           onKeyUp(event);
					break;
					case SDL_MOUSEBUTTONDOWN: onMouseDown(event);
					break;
					case SDL_MOUSEBUTTONUP:   onMouseUp(event);
					break;
					case SDL_MOUSEMOTION:     onMouseMotion(event);
					break;
					case SDL_MOUSEWHEEL:      onMouseWheel(event);
					break;
					case SDL_TEXTINPUT:
						import core.stdc.string : strlen;
						auto len = strlen(&event.text.text[0]);
						if (!len)
							break;
						assert(len < event.text.text.sizeof);
						auto txt = event.text.text[0..len];
						import std.utf : byDchar;
						foreach(ch; txt.byDchar)
							screen.keyboardCharacterEvent(ch);
					break;
					default:
				}
			}

            auto size = window.getSize();
			screen.size = Vector2i(size.x, size.y);
			screen.draw(nvg);

			window.swapBuffers();
		}
	}

	abstract void onVisibleForTheFirstTime();

protected:
	SDL2Window window;
	int width;
	int height;

	MouseButton btn;
	MouseAction action;
	int modifiers;

	Logger _log;
	OpenGL _gl;
	SDL2 _sdl2;

	NVGContext nvg;
	Screen screen;

	public void onKeyDown(ref const(SDL_Event) event)
	{
		import nanogui.common : KeyAction;
		int modifiers;

		auto key = event.key.keysym.sym.convertSdlKeyToNanoguiKey;
		screen.keyboardEvent(key, event.key.keysym.scancode, KeyAction.Press, modifiers);
	}

	public void onKeyUp(ref const(SDL_Event) event)
	{
		
	}

	public void onMouseWheel(ref const(SDL_Event) event)
	{
		if (event.wheel.y > 0)
		{
			btn = MouseButton.WheelUp;
			screen.scrollCallbackEvent(0, +1, Clock.currTime.stdTime);
		}
		else if (event.wheel.y < 0)
		{
			btn = MouseButton.WheelDown;
			screen.scrollCallbackEvent(0, -1, Clock.currTime.stdTime);
		}
	}
	
	public void onMouseMotion(ref const(SDL_Event) event)
	{
		import gfm.sdl2 : SDL_BUTTON_LMASK, SDL_BUTTON_RMASK, SDL_BUTTON_MMASK;

		auto mouse_x = event.motion.x;
		auto mouse_y = event.motion.y;

		if (event.motion.state & SDL_BUTTON_LMASK)
			btn = MouseButton.Left;
		else if (event.motion.state & SDL_BUTTON_RMASK)
			btn = MouseButton.Right;
		else if (event.motion.state & SDL_BUTTON_MMASK)
			btn = MouseButton.Middle;

		if (event.motion.state & SDL_BUTTON_LMASK)
			modifiers |= MouseButton.Left;
		if (event.motion.state & SDL_BUTTON_RMASK)
			modifiers |= MouseButton.Right;
		if (event.motion.state & SDL_BUTTON_MMASK)
			modifiers |= MouseButton.Middle;

		action = MouseAction.Motion;
		screen.cursorPosCallbackEvent(mouse_x, mouse_y, Clock.currTime.stdTime);
	}

	public void onMouseUp(ref const(SDL_Event) event)
	{
		import gfm.sdl2 : SDL_BUTTON_LEFT, SDL_BUTTON_RIGHT, SDL_BUTTON_MIDDLE;

		switch(event.button.button)
		{
			case SDL_BUTTON_LEFT:
				btn = MouseButton.Left;
			break;
			case SDL_BUTTON_RIGHT:
				btn = MouseButton.Right;
			break;
			case SDL_BUTTON_MIDDLE:
				btn = MouseButton.Middle;
			break;
			default:
		}
		action = MouseAction.Release;
		screen.mouseButtonCallbackEvent(btn, action, modifiers, Clock.currTime.stdTime);
	}

	public void onMouseDown(ref const(SDL_Event) event)
	{
		import gfm.sdl2 : SDL_BUTTON_LEFT, SDL_BUTTON_RIGHT, SDL_BUTTON_MIDDLE;

		switch(event.button.button)
		{
			case SDL_BUTTON_LEFT:
				btn = MouseButton.Left;
			break;
			case SDL_BUTTON_RIGHT:
				btn = MouseButton.Right;
			break;
			case SDL_BUTTON_MIDDLE:
				btn = MouseButton.Middle;
			break;
			default:
		}
		action = MouseAction.Press;
		screen.mouseButtonCallbackEvent(btn, action, modifiers, Clock.currTime.stdTime);
	}
}

private auto convertSdlKeyToNanoguiKey(int sdlkey)
{
	import gfm.sdl2;
	import nanogui.common : KeyAction, Key;

	int nanogui_key;
	switch(sdlkey)
	{
		case SDLK_LEFT:
			nanogui_key = Key.Left;
		break;
		case SDLK_RIGHT:
			nanogui_key = Key.Right;
		break;
		case SDLK_UP:
			nanogui_key = Key.Up;
		break;
		case SDLK_DOWN:
			nanogui_key = Key.Down;
		break;
		case SDLK_BACKSPACE:
			nanogui_key = Key.Backspace;
		break;
		case SDLK_DELETE:
			nanogui_key = Key.Delete;
		break;
		case SDLK_HOME:
			nanogui_key = Key.Home;
		break;
		case SDLK_END:
			nanogui_key = Key.End;
		break;
		default:
			nanogui_key = sdlkey;
	}

	return nanogui_key;
}