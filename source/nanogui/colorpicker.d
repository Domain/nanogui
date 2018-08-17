///
module nanogui.colorpicker;

import nanogui.widget;
import nanogui.button;
import nanogui.popupbutton;
import nanogui.colorwheel;
import nanogui.popup;
import nanogui.layout;
import nanogui.common : Vector2i, Color, contrastingColor;

class ColorPicker : PopupButton
{
public:
    this(Widget parent, Color color = Color(255, 0, 0, 255))
    {
        super(parent, "");
        backgroundColor(color);
        Popup popup = this.popup();
        popup.layout(new GroupLayout());

        // initialize callback to do nothing; this is for users to hook into
        // receiving a new color value
        mCallback = (Color c) {  };
        mFinalCallback = (Color c) {  };

        // set the color wheel to the specified color
        mColorWheel = new ColorWheel(popup, color);

        // set the pick button to the specified color
        mPickButton = new Button(popup, "Pick");
        mPickButton.backgroundColor(color);
        mPickButton.textColor(color.contrastingColor());
        mPickButton.fixedSize(Vector2i(100, 20));

        // set the reset button to the specified color
        mResetButton = new Button(popup, "Reset");
        mResetButton.backgroundColor(color);
        mResetButton.textColor(color.contrastingColor());
        mResetButton.fixedSize(Vector2i(100, 20));

        super.changeCallback((bool) {
            if (this.mPickButton.pushed())
            {
                this.color = backgroundColor;
                mFinalCallback(backgroundColor);
            }
        });

        mColorWheel.callback((Color value) {
            mPickButton.backgroundColor = value;
            mPickButton.textColor = value.contrastingColor();
            mCallback(value);
        });

        mPickButton.callback(() {
            if (mPushed)
            {
                Color value = mColorWheel.color();
                pushed(false);
                this.color = value;
                mFinalCallback(value);
            }
        });
        mResetButton.callback(() {
            Color bg = this.mResetButton.backgroundColor();
            Color fg = this.mResetButton.textColor();

            mColorWheel.color(bg);
            mPickButton.backgroundColor(bg);
            mPickButton.textColor(fg);

            mCallback(bg);
            mFinalCallback(bg);
        });
    }

    /// The callback executed when the ColorWheel changes.
    final void delegate(Color) callback() const
    {
        return mCallback;
    }

    /**
     * Sets the callback is executed as the ColorWheel itself is changed.  Set
     * this callback if you need to receive updates for the ColorWheel changing
     * before the user clicks \ref nanogui::ColorPicker::mPickButton or
     * \ref nanogui::ColorPicker::mPickButton.
     */
    final void callback(void delegate(Color) callback)
    {
        mCallback = callback;
        mCallback(backgroundColor);
    }

    /**
     * The callback to execute when a new Color is selected on the ColorWheel
     * **and** the user clicks the \ref nanogui::ColorPicker::mPickButton or
     * \ref nanogui::ColorPicker::mResetButton.
     */
    final void delegate(Color) finalCallback() const
    {
        return mFinalCallback;
    }

    /**
     * The callback to execute when a new Color is selected on the ColorWheel
     * **and** the user clicks the \ref nanogui::ColorPicker::mPickButton or
     * \ref nanogui::ColorPicker::mResetButton.
     */
    final void finalCallback(void delegate(Color) callback)
    {
        mFinalCallback = callback;
    }

    /// Get the current Color selected for this ColorPicker.
    final Color color() const
    {
        return backgroundColor;
    }

    /// Set the current Color selected for this ColorPicker.
    final void color(Color color)
    {
        /* Ignore setColor() calls when the user is currently editing */
        if (!mPushed)
        {
            Color fg = color.contrastingColor();
            backgroundColor(color);
            textColor(fg);
            mColorWheel.color(color);

            mPickButton.backgroundColor(color);
            mPickButton.textColor(fg);

            mResetButton.backgroundColor(color);
            mResetButton.textColor(fg);
        }
    }

    /// The current caption of the \ref nanogui::ColorPicker::mPickButton.
    final string pickButtonCaption()
    {
        return mPickButton.caption;
    }

    /// Sets the current caption of the \ref nanogui::ColorPicker::mPickButton.
    final void pickButtonCaption(string caption)
    {
        mPickButton.caption = caption;
    }

    /// The current caption of the \ref nanogui::ColorPicker::mResetButton.
    final string resetButtonCaption()
    {
        return mResetButton.caption;
    }

    /// Sets the current caption of the \ref nanogui::ColorPicker::mResetButton.
    final void resetButtonCaption(string caption)
    {
        mResetButton.caption = caption;
    }

protected:
    /// The "fast" callback executed when the ColorWheel has changed.
    void delegate(Color) mCallback;

    /**
     * The callback to execute when a new Color is selected on the ColorWheel
     * **and** the user clicks the \ref nanogui::ColorPicker::mPickButton or
     * \ref nanogui::ColorPicker::mResetButton.
     */
    void delegate(Color) mFinalCallback;

    /// The ColorWheel for this ColorPicker (the actual widget allowing selection).
    ColorWheel mColorWheel;

    /**
     * The Button used to signal that the current value on the ColorWheel is the
     * desired color to be chosen.  The default value for the caption of this
     * Button is ``"Pick"``.  You can change it using
     * \ref nanogui::ColorPicker::setPickButtonCaption if you need.
     *
     * The color of this Button will not affect \ref nanogui::ColorPicker::color
     * until the user has actively selected by clicking this pick button.
     * Similarly, the \ref nanogui::ColorPicker::mCallback function is only
     * called when a user selects a new Color using by clicking this Button.
     */
    Button mPickButton;

    /**
     * Remains the Color of the active color selection, until the user picks a
     * new Color on the ColorWheel **and** selects the
     * \ref nanogui::ColorPicker::mPickButton.  The default value for the
     * caption of this Button is ``"Reset"``.  You can change it using
     * \ref nanogui::ColorPicker::setResetButtonCaption if you need.
     */
    Button mResetButton;
}
