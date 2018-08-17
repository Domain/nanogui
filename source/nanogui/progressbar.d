module nanogui.progressbar;

/*
    nanogui/progressbar.h -- Standard widget for visualizing progress

    NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
    The widget drawing code is based on the NanoVG demo application
    by Mikko Mononen.

    All rights reserved. Use of this source code is governed by a
    BSD-style license that can be found in the LICENSE.txt file.
*/

import nanogui.widget;
import nanogui.common : Vector2i, Color;

/**
 * \class ProgressBar progressbar.h nanogui/progressbar.h
 *
 * \brief Standard widget for visualizing progress.
 */
class ProgressBar : Widget
{
public:
    this(Widget parent)
    {
        super(parent);
    }

    final float value() const
    {
        return mValue;
    }

    final value(float value)
    {
        mValue = value;
    }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        return Vector2i(70, 12);
    }

    override void draw(NVGContext nvg)
    {
        super.draw(nvg);

        NVGPaint paint = nvg.boxGradient(mPos.x + 1, mPos.y + 1, mSize.x - 2,
                mSize.y, 3, 4, Color(0, 0, 0, 32), Color(0, 0, 0, 92));
        nvg.beginPath;
        nvg.roundedRect(mPos.x, mPos.y, mSize.x, mSize.y, 3);
        nvg.fillPaint(paint);
        nvg.fill();

        import std.algorithm.comparison : min, max;
        import std.math : round;

        float value = min(max(0.0f, mValue), 1.0f);
        int barPos = cast(int) round((mSize.x - 2) * value);

        paint = nvg.boxGradient(mPos.x, mPos.y, barPos + 1.5f, mSize.y - 1, 3, 4,
                Color(220, 220, 220, 100), Color(128, 128, 128, 100));

        nvg.beginPath();
        nvg.roundedRect(mPos.x + 1, mPos.y + 1, barPos, mSize.y - 2, 3);
        nvg.fillPaint(paint);
        nvg.fill();
    }

protected:
    float mValue;
}
