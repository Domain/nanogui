///
module nanogui.scrollpanel;

/*
    nanogui/vscrollpanel.h -- Adds a vertical scrollbar around a widget
    that is too big to fit into a certain area

    NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
    The widget drawing code is based on the NanoVG demo application
    by Mikko Mononen.

    All rights reserved. Use of this source code is governed by a
    BSD-style license that can be found in the LICENSE.txt file.
*/
import std.algorithm : min, max;
import nanogui.widget;
import nanogui.common : MouseButton, Vector2f, Vector2i, NVGContext;

/**
 * Adds a vertical scrollbar around a widget that is too big to fit into
 * a certain area.
 */
class ScrollPanel : Widget {
public:
    this(Widget parent)
    {
        super(parent);
        mChildPreferredWidth = 0;
        mChildPreferredHeight = 0;
        mHScroll = 0.0f;
        mVScroll = 0.0f;
        mUpdateLayout = false;
    }

    /// Return the current scroll amount as a value between 0 and 1. 0 means scrolled to the top and 1 to the bottom.
    float vScroll() const { return mVScroll; }
    /// Set the scroll amount to a value between 0 and 1. 0 means scrolled to the top and 1 to the bottom.
    void vScroll(float scroll) { mVScroll = scroll; }
    float hScroll() const { return mHScroll; }
    void hScroll(float scroll) { mHScroll = scroll; }

    override void performLayout(NVGContext nvg)
    {
        super.performLayout(nvg);

        if (mChildren.empty)
            return;
        if (mChildren.length > 1)
            throw new Exception("VScrollPanel should have one child.");

        Widget child = mChildren[0];
        mChildPreferredWidth = child.preferredSize(nvg).x;
        mChildPreferredHeight = child.preferredSize(nvg).y;

        auto x = 0;
        auto y = 0;

        if (mChildPreferredWidth > mSize.x)
        {
            x = cast(int) (-mHScroll*(mChildPreferredWidth - mSize.x));
        }
        else 
        {
            mHScroll = 0;
        }

        if (mChildPreferredHeight > mSize.y)
        {
            y = cast(int) (-mVScroll*(mChildPreferredHeight - mSize.y));
        }
        else 
        {
            mVScroll = 0;
        }

        child.position(Vector2i(x, y));
        child.performLayout(nvg);
    }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        if (mChildren.empty)
            return Vector2i(0, 0);
        return mSize + Vector2i(theme.mScrollbarWidth, theme.mScrollbarWidth);//mChildren[0].preferredSize(nvg) + Vector2i(12, 0);
    }

    override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
    {
        mHCaptured = false;
        mVCaptured = false;

        if (button == MouseButton.Left && down)
        {
            if (!mChildren.empty)
            {
                if (mChildPreferredHeight > mSize.y && p.x >= mSize.x - 13)
                {
                    mVCaptured = true;
                    return true;
                }

                if (mChildPreferredWidth > mSize.x && p.y >= mSize.y - 13)
                {
                    mHCaptured = true;
                    return true;
                }
            }
        }

        return super.mouseButtonEvent(p, button, down, modifiers);
    }
    
    override bool mouseDragEvent(Vector2i p, Vector2i rel, MouseButton button, int modifiers)
    {
        if (!mChildren.empty && (mChildPreferredHeight > mSize.y || mChildPreferredWidth > mSize.x)) {
            
            if (!mHCaptured)
            {
                float scrollh = height *
                    min(1.0f, height / cast(float)mChildPreferredHeight);

                mVScroll = max(cast(float) 0.0f, min(cast(float) 1.0f,
                            mVScroll + rel.y / cast(float)(mSize.y - 8 - scrollh)));
            }

            if (!mVCaptured)
            {
                float scrollv = width *
                    min(1.0f, width / cast(float)mChildPreferredWidth);

                mHScroll = max(cast(float) 0.0f, min(cast(float) 1.0f,
                            mHScroll + rel.x / cast(float)(mSize.x - 8 - scrollv)));
            }
            mUpdateLayout = true;
            return true;
        } else {
            return super.mouseDragEvent(p, rel, button, modifiers);
        }
    }

    override bool scrollEvent(Vector2i p, Vector2f rel)
    {
        if (!mChildren.empty && (mChildPreferredHeight > mSize.y || mChildPreferredWidth > mSize.x))
        {
            const scrollHAmount = rel.y * (mSize.y / 20.0f);
            float scrollh = height *
                min(1.0f, height / cast(float)mChildPreferredHeight);

            mVScroll = max(cast(float) 0.0f, min(cast(float) 1.0f,
                    mVScroll - scrollHAmount / cast(float)(mSize.y - 8 - scrollh)));

            const scrollVAmount = rel.x * (mSize.x / 20.0f);
            float scrollv = width *
                min(1.0f, width / cast(float)mChildPreferredWidth);

            mHScroll = max(cast(float) 0.0f, min(cast(float) 1.0f,
                    mHScroll - scrollVAmount / cast(float)(mSize.x - 8 - scrollv)));

            mUpdateLayout = true;
            return true;
        } else {
            return super.scrollEvent(p, rel);
        }
    }

    override void draw(NVGContext nvg)
    {
        if (mChildren.empty)
            return;
        Widget child = mChildren[0];
        auto x = cast(int) (-mHScroll*(mChildPreferredWidth - mSize.x));
        auto y = cast(int) (-mVScroll*(mChildPreferredHeight - mSize.y));
        child.position(Vector2i(x, y));

        auto preferredSize = child.preferredSize(nvg);
        mChildPreferredWidth = preferredSize.x;
        mChildPreferredHeight = preferredSize.y;

        float scrollv = width *
            min(1.0f, width / cast(float) (mChildPreferredWidth + (mChildPreferredWidth > mSize.x ? theme.mScrollbarWidth : 0)));
        float scrollh = height *
            min(1.0f, height / cast(float) (mChildPreferredHeight + (mChildPreferredHeight > mSize.y ? theme.mScrollbarWidth : 0)));

        if (mUpdateLayout)
            child.performLayout(nvg);

        nvg.save;
        nvg.translate(mPos.x, mPos.y);
        nvg.intersectScissor(0, 0, mSize.x - theme.mScrollbarWidth, mSize.y - theme.mScrollbarWidth);
        if (child.visible)
            child.draw(nvg);
        nvg.restore;

        if (mChildPreferredWidth > mSize.x)
        {
            NVGPaint paint = nvg.boxGradient(
                mPos.x + 4 + 1, mPos.y + mSize.y - theme.mScrollbarWidth + 1, mSize.x - 8,
                8, 3, 4, Color(0, 0, 0, 32), Color(0, 0, 0, 92));
            nvg.beginPath;
            nvg.roundedRect(mPos.x + 4, mPos.y + mSize.y - theme.mScrollbarWidth, mSize.x - 8,
                        8, 3);
            nvg.fillPaint(paint);
            nvg.fill;

            paint = nvg.boxGradient(
                mPos.x + 4 + (mSize.x - 8 - scrollv) * mHScroll - 1,
                mPos.y + mSize.y - theme.mScrollbarWidth - 1, scrollv, 8,
                3, 4, Color(220, 220, 220, 100), Color(128, 128, 128, 100));

            nvg.beginPath;
            nvg.roundedRect(mPos.x + 4 + 1 + (mSize.x - 8 - scrollv) * mHScroll,
                        mPos.y + mSize.y - theme.mScrollbarWidth + 1, scrollv - 2,
                        8 - 2, 2);
            nvg.fillPaint(paint);
            nvg.fill;
        }

        if (mChildPreferredHeight > mSize.y)
        {
            NVGPaint paint = nvg.boxGradient(
                mPos.x + mSize.x - theme.mScrollbarWidth + 1, mPos.y + 4 + 1, 8,
                mSize.y - 8, 3, 4, Color(0, 0, 0, 32), Color(0, 0, 0, 92));
            nvg.beginPath;
            nvg.roundedRect(mPos.x + mSize.x - theme.mScrollbarWidth, mPos.y + 4, 8,
                        mSize.y - 8, 3);
            nvg.fillPaint(paint);
            nvg.fill;

            paint = nvg.boxGradient(
                mPos.x + mSize.x - theme.mScrollbarWidth - 1,
                mPos.y + 4 + (mSize.y - 8 - scrollh) * mVScroll - 1, 8, scrollh,
                3, 4, Color(220, 220, 220, 100), Color(128, 128, 128, 100));

            nvg.beginPath;
            nvg.roundedRect(mPos.x + mSize.x - theme.mScrollbarWidth + 1,
                        mPos.y + 4 + 1 + (mSize.y - 8 - scrollh) * mVScroll, 8 - 2,
                        scrollh - 2, 2);
            nvg.fillPaint(paint);
            nvg.fill;
        }
    }
    // override void save(Serializer &s) const;
    // override bool load(Serializer &s);
protected:
    int mChildPreferredWidth;
    int mChildPreferredHeight;
    float mVScroll;
    float mHScroll;
    bool mUpdateLayout;
    bool mHCaptured = false;
    bool mVCaptured = false;
}
