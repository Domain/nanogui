module examples.sdl;

import std.datetime : Clock;
import arsd.nanovega;
import nanogui.sdlbackend : SdlBackend;
import nanogui;
import std.stdio;

class MyGui : SdlBackend
{
	this(int w, int h, string title)
	{
		super(w, h, title);
	}

	override void onVisibleForTheFirstTime()
	{
		{
			Window window = new Window(screen, "Button demo");
			window.position(Vector2i(15, 15));
			window.layout(new GroupLayout());

			/* No need to store a pointer, the data structure will be automatically
			freed when the parent window is deleted */
			new Label(window, "Push buttons", "sans-bold");

			Button b = new Button(window, "Plain button");
			b.callback(() { writeln("pushed!"); });
			b.tooltip("short tooltip");

			/* Alternative construction notation using variadic template */
			b = window.add!Button("Styled", Entypo.ICON_ROCKET);
			b.backgroundColor(Color(0, 0, 255, 25));
			b.callback(() { writeln("pushed!"); });
			b.tooltip("screen button has a fairly long tooltip. It is so long, in " ~
					"fact, that the shown text will span several lines.");

			new Label(window, "Toggle buttons", "sans-bold");
			b = new Button(window, "Toggle me");
			b.flags(Button.Flags.ToggleButton);
			b.changeCallback((bool state) { writefln("Toggle button state: %s", state); });

			new Label(window, "Radio buttons", "sans-bold");
			b = new Button(window, "Radio button 1");
			b.flags(Button.Flags.RadioButton);
			b = new Button(window, "Radio button 2");
			b.flags(Button.Flags.RadioButton);

			new Label(window, "A tool palette", "sans-bold");
			Widget tools = new Widget(window);
			tools.layout(new BoxLayout(Orientation.Horizontal,
										Alignment.Middle, 0, 6));

			b = new ToolButton(tools, Entypo.ICON_CLOUD);
			b = new ToolButton(tools, Entypo.ICON_CONTROLLER_FAST_FORWARD);
			b = new ToolButton(tools, Entypo.ICON_COMPASS);
			b = new ToolButton(tools, Entypo.ICON_INSTALL);

			new Label(window, "Popup buttons", "sans-bold");
			PopupButton popupBtn = new PopupButton(window, "Popup", Entypo.ICON_EXPORT);
			Popup popup = popupBtn.popup();
			popup.layout(new GroupLayout());
			new Label(popup, "Arbitrary widgets can be placed here");
			new CheckBox(popup, "A check box");
			// popup right
			popupBtn = new PopupButton(popup, "Recursive popup", Entypo.ICON_FLASH);
			Popup popupRight = popupBtn.popup();
			popupRight.layout(new GroupLayout());
			new CheckBox(popupRight, "Another check box");
			// popup left
			popupBtn = new PopupButton(popup, "Recursive popup", Entypo.ICON_FLASH);
			popupBtn.side(Popup.Side.Left);
			Popup popupLeft = popupBtn.popup();
			popupLeft.layout(new GroupLayout());
			new CheckBox(popupLeft, "Another check box");
		}

		{
			auto window = new Window(screen, "Basic widgets");
			window.position(Vector2i(200, 15));
			window.layout(new GroupLayout());

			new Label(window, "Message dialog", "sans-bold");
			auto tools = new Widget(window);
			tools.layout(new BoxLayout(Orientation.Horizontal,
										Alignment.Middle, 0, 6));
			auto b = new Button(tools, "Info");
			b.callback(() {
				auto dlg = new MessageDialog(screen, MessageDialog.Type.Information, "Title", "screen is an information message");
				dlg.callback((int result) { writefln("Dialog result: %s", result); });
			});
			b = new Button(tools, "Warn");
			b.callback(() {
				auto dlg = new MessageDialog(screen, MessageDialog.Type.Warning, "Title", "screen is a warning message");
				dlg.callback((int result) { writefln("Dialog result: %s", result); });
			});
			b = new Button(tools, "Ask");
			b.callback(() {
				auto dlg = new MessageDialog(screen, MessageDialog.Type.Question, "Title", "screen is a question message", "Yes", "No", true);
				dlg.callback((int result) { writefln("Dialog result: %s", result); });
			});

			// vector<pair<int, string>>
			// 	icons = loadImageDirectory(mNVGContext, "icons");
			// #if defined(_WIN32)
			// 	string resourcesFolderPath("../resources/");
			// #else
			// 	string resourcesFolderPath("./");
			// #endif

			new Label(window, "Image panel & scroll panel", "sans-bold");
			PopupButton imagePanelBtn = new PopupButton(window, "Image Panel");
			imagePanelBtn.icon(Entypo.ICON_FOLDER);
			auto popup = imagePanelBtn.popup();
			auto vscroll = new ScrollPanel(popup);
			/*ImagePanel imgPanel = new ImagePanel(vscroll);
			imgPanel.setImages(icons);*/
			popup.fixedSize(Vector2i(245, 150));

			auto imageWindow = new Window(screen, "Selected image");
			imageWindow.position(Vector2i(710, 15));
			imageWindow.layout(new GroupLayout());

			// Load all of the images by creating a GLTexture object and saving the pixel data.
			/*foreach (icon; icons) {
				GLTexture texture(icon.second);
				auto data = texture.load(resourcesFolderPath + icon.second + ".png");
				mImagesData.emplace_back(std.move(texture), std.move(data));
			}

			// Set the first texture
			auto imageView = new ImageView(imageWindow, mImagesData[0].first.texture());
			mCurrentImage = 0;
			// Change the active textures.
			imgPanel.callback([screen, imageView](int i) {
				imageView.bindImage(mImagesData[i].first.texture());
				mCurrentImage = i;
				writefln("Selected item ", i, '\n';
			});
			imageView.setGridThreshold(20);
			imageView.setPixelInfoThreshold(20);
			imageView.setPixelInfoCallback(
				[screen, imageView](const Vector2i& index) . pair<string, Color> {
				auto& imageData = mImagesData[mCurrentImage].second;
				auto& textureSize = imageView.imageSize();
				string stringData;
				uint16_t channelSum = 0;
				for (int i = 0; i != 4; ++i) {
					auto& channelData = imageData[4*index.y()*textureSize.x() + 4*index.x() + i];
					channelSum += channelData;
					stringData += (to_string(static_cast!int(channelData)) + "\n");
				}
				float intensity = static_cast<float>(255 - (channelSum / 4)) / 255.0f;
				float colorScale = intensity > 0.5f ? (intensity + 1) / 2 : intensity / 2;
				Color textColor = Color(colorScale, 1.0f);
				return { stringData, textColor };
			});*/

			new Label(window, "File dialog", "sans-bold");
			tools = new Widget(window);
			tools.layout(new BoxLayout(Orientation.Horizontal,
										Alignment.Middle, 0, 6));
			b = new Button(tools, "Open");
			// b.callback(() {
			// 	writefln("File dialog result: ", file_dialog(
			// 			{ {"png", "Portable Network Graphics"}, {"txt", "Text file"} }, false));
			// });
			b = new Button(tools, "Save");
			// b.callback(() {
			// 	writefln("File dialog result: ", file_dialog(
			// 			{ {"png", "Portable Network Graphics"}, {"txt", "Text file"} }, true));
			// });

			new Label(window, "Combo box", "sans-bold");
			new ComboBox(window, ["Combo box item 1", "Combo box item 2", "Combo box item 3"]);
			new Label(window, "Check box", "sans-bold");
			CheckBox cb = new CheckBox(window, "Flag 1",
				(bool state) { writefln("Check box 1 state: %s", state); }
			);
			cb.checked(true);
			cb = new CheckBox(window, "Flag 2",
				(bool state) { writefln("Check box 2 state: %s", state); }
			);
			new Label(window, "Progress bar", "sans-bold");
			auto mProgress = new ProgressBar(window);
			mProgress.value = 0.5f;

			new Label(window, "Slider and text box", "sans-bold");

			Widget panel = new Widget(window);
			panel.layout(new BoxLayout(Orientation.Horizontal,
										Alignment.Middle, 0, 20));

			Slider slider = new Slider(panel);
			slider.value(0.5f);
			slider.fixedWidth(80);

			TextBox textBox = new TextBox(panel);
			textBox.fixedSize(Vector2i(60, 25));
			textBox.value("50");
			textBox.units("%");
			slider.callback((float value) {
				import std.conv : to;
				textBox.value(to!string(cast(int)(value * 100)));
			});
			slider.finalCallback((float value) {
				writefln("Final slider value: %s", cast(int) (value * 100));
			});
			textBox.fixedSize(Vector2i(60,25));
			textBox.fontSize(20);
			textBox.alignment(TextBox.Alignment.Right);
		}

		{
			auto window = new Window(screen, "Misc. widgets");
			window.position = Vector2i(425,15);
			window.layout = new GroupLayout();

			TabWidget tabWidget = window.add!TabWidget();

			Widget layer = tabWidget.createTab("Color Wheel");
			layer.layout = new GroupLayout();

			// Use overloaded variadic add to fill the tab widget with Different tabs.
			layer.add!Label("Color wheel widget", "sans-bold");
			layer.add!ColorWheel();

			layer = tabWidget.createTab("Function Graph");
			layer.layout = new GroupLayout();

			layer.add!Label("Function graph widget", "sans-bold");

			Graph graph = layer.add!Graph("Some Function");

			import std.math : abs, sin, cos;
			graph.header("E = 2.35e-3");
			graph.footer("Iteration 89");
			float[] func;
			for (int i = 0; i < 100; ++i)
				func ~= 0.5f * (0.5f * sin(i / 10.0f) +
								0.5f * cos(i / 23.0f) + 1);
			graph.values = func;

			// Dummy tab used to represent the last tab button.
			tabWidget.createTab("+");

			// A simple counter.
			int counter = 1;
			tabWidget.callback((int index) {
				if (index == (tabWidget.tabCount()-1)) {
					// When the "+" tab has been clicked, simply add a new tab.
					import std.conv : text;
					string tabName = "Dynamic " ~ counter.text;
					Widget layerDyn = tabWidget.createTab(index, tabName);
					layerDyn.layout = new GroupLayout();
					layerDyn.add!Label("Function graph widget", "sans-bold");
					Graph graphDyn = layerDyn.add!Graph("Dynamic function");

					graphDyn.header("E = 2.35e-3");
					graphDyn.footer("Iteration " ~ (index*counter).text);
					float[] funcDyn;
					for (int i = 0; i < 100; ++i)
						funcDyn ~= 0.5f * abs((0.5f * sin(i / 10.0f + counter) + 0.5f * cos(i / 23.0f + 1 + counter)));
					++counter;
					// We must invoke perform layout from the screen instance to keep everything in order.
					// This is essential when creating tabs dynamically.
					nvg.beginFrame(screen.size.x, screen.size.y);
					screen.performLayout(nvg);
					nvg.endFrame();
					// Ensure that the newly added header is visible on screen
					tabWidget.ensureTabVisible(index);
				}
			});
			tabWidget.activeTab(0);

			// A button to go back to the first tab and scroll the window.
			auto panel = window.add!Widget();
			panel.add!Label("Jump to tab: ");
			panel.layout = new BoxLayout(Orientation.Horizontal,
										Alignment.Middle, 0, 6);

			auto ib = panel.add!(IntBox!int)();
			ib.editable(true);

			auto b = panel.add!Button("", Entypo.ICON_FORWARD);
			b.fixedSize(Vector2i(22, 22));
			ib.fixedHeight(22);
			b.callback(() {
				int value = ib.value();
				if (value >= 0 && value < tabWidget.tabCount()) {
					tabWidget.activeTab(value);
					tabWidget.ensureTabVisible(value);
				}
			});
		}

		{
			import std.container.array : Array;

			auto window = new Window(screen, "Grid of small widgets");
			window.position(Vector2i(425, 300));
			GridLayout layout =
				new GridLayout(Orientation.Horizontal, 2,
							Alignment.Middle, 15, 5);
			layout.colAlignment(Array!Alignment( Alignment.Maximum, Alignment.Fill ));
			layout.spacing(0, 10);
			window.layout(layout);

			/* FP widget */ {
				new Label(window, "Floating point :", "sans-bold");
				auto textBox = new FloatBox!float(window);
				textBox.editable(true);
				textBox.fixedSize(Vector2i(100, 20));
				textBox.value(50.0f);
				textBox.units("GiB");
				textBox.defaultValue("0.0");
				textBox.fontSize(16);
				textBox.format("[-]?[0-9]*\\.?[0-9]+");
			}

			/* Positive integer widget */ {
				new Label(window, "Positive integer :", "sans-bold");
				auto intBox = new IntBox!int(window);
				intBox.editable(true);
				intBox.fixedSize(Vector2i(100, 20));
				intBox.value(50);
				intBox.units("Mhz");
				intBox.defaultValue("0");
				intBox.fontSize(16);
				intBox.format("[1-9][0-9]*");
				intBox.spinnable(true);
				intBox.minValue(1);
				intBox.valueIncrement(2);
			}

			/* Checkbox widget */ {
				new Label(window, "Checkbox :", "sans-bold");

				auto cb = new CheckBox(window, "Check me");
				cb.fontSize(16);
				cb.checked(true);
			}

			new Label(window, "Combo box :", "sans-bold");
			ComboBox cobo =
				new ComboBox(window, [ "Item 1", "Item 2", "Item 3" ]);
			cobo.fontSize(16);
			cobo.fixedSize(Vector2i(100,20));

			new Label(window, "Color picker :", "sans-bold");
			auto cp = new ColorPicker(window, Color(255, 120, 0, 255));
			cp.fixedSize(Vector2i(100, 20));
			cp.finalCallback((Color c) {
				writefln("ColorPicker Final Callback: [%s, %s, %s, %s]", c.r, c.g, c.b, c.a);
			});

			window = new Window(screen, "Color Picker Fast Callback");
			layout =
				new GridLayout(Orientation.Horizontal, 2,
							Alignment.Middle, 15, 5);
			layout.colAlignment(Array!Alignment( Alignment.Maximum, Alignment.Fill ));
			layout.spacing(0, 10);
			window.layout(layout);
			window.position(Vector2i(425, 500));
			new Label(window, "Combined: ");
			auto b = new Button(window, "ColorWheel", Entypo.ICON_500PX);
			new Label(window, "Red: ");
			auto redIntBox = new IntBox!int(window);
			redIntBox.editable(false);
			new Label(window, "Green: ");
			auto greenIntBox = new IntBox!int(window);
			greenIntBox.editable(false);
			new Label(window, "Blue: ");
			auto blueIntBox = new IntBox!int(window);
			blueIntBox.editable(false);
			new Label(window, "Alpha: ");
			auto alphaIntBox = new IntBox!int(window);
			cp.callback((Color c) {
				b.backgroundColor(c);
				b.textColor(c.contrastingColor());
				int red = cast(int) (c.r);
				redIntBox.value(red);
				int green = cast(int) (c.g);
				greenIntBox.value(green);
				int blue = cast(int) (c.b);
				blueIntBox.value(blue);
				int alpha = cast(int) (c.a);
				alphaIntBox.value(alpha);

			});
		}

		{
			int width = 1000;
			int half_width = width / 2;
			int height = 300;

			auto window = new Window(screen, "All Icons");
			window.position(Vector2i(700, 400));
			window.fixedSize(Vector2i(width, height + window.theme.mWindowHeaderHeight));
			window.layout = new BoxLayout(Orientation.Horizontal);

			// attach a vertical scroll panel
			auto vscroll = new ScrollPanel(window);
			vscroll.fixedSize(Vector2i(width, height));

			// vscroll should only have *ONE* child. screen is what `wrapper` is for
			auto wrapper = new Widget(vscroll);
			// wrapper.fixedSize(Vector2i(width, height));
			wrapper.layout(new GridLayout()); // defaults: 2 columns

			// foreach (i; 0 .. 100)
			{
				import std.conv : text;
				import std.traits : EnumMembers;

				foreach (member; EnumMembers!Entypo)
				{
					auto item = new Button(wrapper, member.text, member);
					item.iconPosition(Button.IconPosition.Left);
					item.fixedWidth(half_width);
				}
			}
		}

		{
			auto asian_theme = new Theme(nvg);

			{
				// sorta hack because loading font in nvg results in
				// conflicting font id
				auto nvg2 = nvgCreateContext(NVGContextFlag.Debug);
				scope (exit)
					nvg2.kill;
				// nvg2.createFont("chihaya", "./resources/fonts/n_chihaya_font.ttf");
				nvg2.createFont("STKAITI", "C:/windows/fonts/STKAITI.TTF");
				nvg.addFontsFrom(nvg2);
				asian_theme.mFontNormal = nvg.findFont("STKAITI");
			}

			auto window = new Window(screen, "Textbox window");
			window.position = Vector2i(900, 15);
			window.fixedSize = Vector2i(200, 350);
			window.layout(new GroupLayout());
			window.tooltip = "Window with TextBoxes";

			auto tb = new TextBox(window, "Россия");
			tb.editable = true;

			tb = new TextBox(window, "England");
			tb.editable = true;

			tb = new TextBox(window, "日本");
			tb.theme = asian_theme;
			tb.editable = true;
			tb.placeholder = "请输入名字";

			tb = new TextBox(window, "中国");
			tb.theme = asian_theme;
			tb.editable = true;

			tb = new IntBox!int(window, 0);
			tb.editable = true;

			tb = new FloatBox!float(window, 3.1415f);
			tb.editable = true;
		}

		// now we should do layout manually yet
		screen.performLayout(nvg);
	}
}

void main()
{
	auto gui = new MyGui(1024, 700, "Nanogui using SDL2 backend");
	gui.run();
}
