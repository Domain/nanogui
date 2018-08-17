///
module nanogui.toolbutton;

/*
    nanogui/toolbutton.h -- Simple radio+toggle button with an icon

    NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
    The widget drawing code is based on the NanoVG demo application
    by Mikko Mononen.

    All rights reserved. Use of this source code is governed by a
    BSD-style license that can be found in the LICENSE.txt file.
*/

import nanogui.button;
import nanogui.widget;
import nanogui.common : Vector2i;

/**
 * \class ToolButton toolbutton.h nanogui/toolbutton.h
 *
 * \brief Simple radio+toggle button with an icon.
 */
class ToolButton : Button
{
public:
    this(Widget parent, dchar icon, string caption = "")
    {   
        super(parent, caption, icon);
        flags = Flags.RadioButton | Flags.ToggleButton;
        fixedSize = Vector2i(25, 25);
    }
}