///
module nanogui.messagedialog;

/*
    nanogui/messagedialog.h -- Simple "OK" or "Yes/No"-style modal dialogs

    NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
    The widget drawing code is based on the NanoVG demo application
    by Mikko Mononen.

    All rights reserved. Use of this source code is governed by a
    BSD-style license that can be found in the LICENSE.txt file.
*/

import nanogui.window;
import nanogui.widget;
import nanogui.label;
import nanogui.button;
import nanogui.layout;

/**
 * \class MessageDialog messagedialog.h nanogui/messagedialog.h
 *
 * \brief Simple "OK" or "Yes/No"-style modal dialogs.
 */
class MessageDialog : Window
{
public:

    /// Classification of the type of message this MessageDialog represents.
    enum Type
    {
        Information,
        Question,
        Warning
    }

    this(Widget parent, Type type, string title = "Untitled", string message = "Message",
            string buttonText = "OK", string altButtonText = "Cancel", bool altButton = false)
    {
        super(parent, title);

        layout(new BoxLayout(Orientation.Vertical, Alignment.Middle, 10, 10));
        modal = true;

        Widget panel1 = new Widget(this);
        panel1.layout(new BoxLayout(Orientation.Horizontal, Alignment.Middle, 10, 15));
        dchar icon = 0;
        final switch (type)
        {
        case Type.Information:
            icon = mTheme.mMessageInformationIcon;
            break;
        case Type.Question:
            icon = mTheme.mMessageQuestionIcon;
            break;
        case Type.Warning:
            icon = mTheme.mMessageWarningIcon;
            break;
        }
        import std.utf : toUTF8;
        Label iconLabel = new Label(panel1, [icon].toUTF8, "icons");
        iconLabel.fontSize = 50;
        mMessageLabel = new Label(panel1, message);
        mMessageLabel.fixedWidth(200);
        Widget panel2 = new Widget(this);
        panel2.layout(new BoxLayout(Orientation.Horizontal, Alignment.Middle, 0, 15));

        if (altButton)
        {
            Button button = new Button(panel2, altButtonText, mTheme.mMessageAltButtonIcon);
            button.callback(() {
                if (mCallback)
                    mCallback(1);
                dispose();
            });
        }
        Button button = new Button(panel2, buttonText, mTheme.mMessagePrimaryButtonIcon);
        button.callback(() {
            if (mCallback)
                mCallback(0);
            dispose();
        });
        center();
        requestFocus();
    }

    final Label messageLabel() { return mMessageLabel; }

    final void delegate(int) callback() const { return mCallback; }
    final void callback(void delegate(int) callback) { mCallback = callback; }

protected:
    void delegate(int) mCallback;
    Label mMessageLabel;
}
