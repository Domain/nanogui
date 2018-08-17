///
module nanogui.stackedwidget;

/*
    nanogui/stackedwidget.h -- Widget used to stack widgets on top
    of each other. Only the active widget is visible.

    The stacked widget was contributed by Stefan Ivanov.

    NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
    The widget drawing code is based on the NanoVG demo application
    by Mikko Mononen.

    All rights reserved. Use of this source code is governed by a
    BSD-style license that can be found in the LICENSE.txt file.
*/

import nanogui.widget;
import nanogui.common : Vector2i;
import gfm.math : maxByElem;

/**
 * \class StackedWidget stackedwidget.h nanogui/stackedwidget.h
 *
 * \brief A stack widget.
 */
class StackedWidget : Widget
{
public:
    this(Widget parent)
    {
        super(parent);
    }

    final void selectedIndex(int index) 
    { 
        assert(index < childCount());
        if (mSelectedIndex >= 0)
            mChildren[mSelectedIndex].visible = false;
        mSelectedIndex = index;
        mChildren[mSelectedIndex].visible = true;
    }

    final int selectedIndex() const { return mSelectedIndex; }

    override void performLayout(NVGContext nvg)
    {
        foreach (child; mChildren) 
        {
            child.position = Vector2i(0, 0);
            child.size = mSize;
            child.performLayout(nvg);
        }
    }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        Vector2i size = Vector2i(0, 0);
        foreach (child; mChildren)
            size = size.maxByElem(child.preferredSize(nvg));
        return size;
    }

    override void addChild(int index, Widget widget) 
    {
        if (mSelectedIndex >= 0)
            mChildren[mSelectedIndex].visible = false;
        super.addChild(index, widget);
        widget.visible = true;
        selectedIndex = index;
    }

private:
    int mSelectedIndex = -1;
}