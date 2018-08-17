///
module nanogui.slider;

import nanogui.widget;
import nanogui.common : Vector2i, Vector2f, Color, MouseButton, KeyAction;
import std.algorithm.comparison : min, max;

/**
 * \class Slider slider.h nanogui/slider.h
 *
 * \brief Fractional slider widget with mouse control.
 */
class Slider : Widget
{
public:
    this(Widget parent)
    {
        super(parent);

        mValue = 0.0f;
        mRange = Vector2f(0.0f, 1.0f);
        mHighlightedRange = Vector2f(0.0f, 0.0f);
        mHighlightColor = Color(255, 80, 80, 70);
    }

    final float value() const
    {
        return mValue;
    }

    final value(float value)
    {
        mValue = value;
    }

    final Vector2f range() const
    {
        return mRange;
    }

    final void range(Vector2f range)
    {
        mRange = range;
    }

    final Vector2f highlightedRange() const
    {
        return mHighlightedRange;
    }

    final void highlightedRange(Vector2f range)
    {
        mHighlightedRange = range;
    }

    final void delegate(float) callback() const
    {
        return mCallback;
    }

    final void callback(void delegate(float) callback)
    {
        mCallback = callback;
    }

    final void delegate(float) finalCallback() const
    {
        return mFinalCallback;
    }

    final void finalCallback(void delegate(float) callback)
    {
        mFinalCallback = callback;
    }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        return Vector2i(70, 16);
    }

    override void draw(NVGContext nvg)
    {
        Vector2f center = cast(Vector2f)(mPos) + cast(Vector2f)(mSize) * 0.5f;
        float kr = cast(int)(mSize.y * 0.4f), kshadow = 3;

        float startX = kr + kshadow + mPos.x;
        float widthX = mSize.x - 2 * (kr + kshadow);

        auto knobPos = Vector2f(startX + (mValue - mRange[0]) / (mRange[1] - mRange[0]) * widthX,
                center.y + 0.5f);

        NVGPaint bg = nvg.boxGradient(startX, center.y - 3 + 1, widthX, 6, 3,
                3, Color(0, 0, 0, mEnabled ? 32 : 10), Color(0, 0, 0, mEnabled ? 128 : 210));

        nvg.beginPath();
        nvg.roundedRect(startX, center.y - 3 + 1, widthX, 6, 2);
        nvg.fillPaint(bg);
        nvg.fill();

        if (mHighlightedRange[1] != mHighlightedRange[0])
        {
            nvg.beginPath();
            nvg.roundedRect(startX + mHighlightedRange[0] * mSize.x,
                    center.y - kshadow + 1,
                    widthX * (mHighlightedRange[1] - mHighlightedRange[0]), kshadow * 2, 2);
            nvg.fillColor(mHighlightColor);
            nvg.fill();
        }

        NVGPaint knobShadow = nvg.radialGradient(knobPos.x, knobPos.y,
                kr - kshadow, kr + kshadow, Color(0, 0, 0, 64), mTheme.mTransparent);

        nvg.beginPath();
        nvg.rect(knobPos.x - kr - 5, knobPos.y - kr - 5, kr * 2 + 10, kr * 2 + 10 + kshadow);
        nvg.circle(knobPos.x, knobPos.y, kr);
        nvg.pathWinding(NVGSolidity.Hole);
        nvg.fillPaint(knobShadow);
        nvg.fill();

        NVGPaint knob = nvg.linearGradient(mPos.x, center.y - kr,
                mPos.x, center.y + kr, mTheme.mBorderLight, mTheme.mBorderMedium);
        NVGPaint knobReverse = nvg.linearGradient(mPos.x, center.y - kr,
                mPos.x, center.y + kr, mTheme.mBorderMedium, mTheme.mBorderLight);

        nvg.beginPath();
        nvg.circle(knobPos.x, knobPos.y, kr);
        nvg.strokeColor(mTheme.mBorderDark);
        nvg.fillPaint(knob);
        nvg.stroke();
        nvg.fill();
        nvg.beginPath();
        nvg.circle(knobPos.x, knobPos.y, kr / 2);
        nvg.fillColor(Color(150, 150, 150, mEnabled ? 255 : 100));
        nvg.strokePaint(knobReverse);
        nvg.stroke();
        nvg.fill();
    }

    override bool mouseDragEvent(Vector2i p, Vector2i rel, MouseButton button, int modifiers)
    {
        if (!mEnabled)
            return false;

        requestFocus();

        immutable float kr = cast(int)(mSize.y * 0.4f), kshadow = 3;
        immutable float startX = kr + kshadow + mPos.x - 1;
        immutable float widthX = mSize.x - 2 * (kr + kshadow);

        float value = (p.x - startX) / widthX;
        value = value * (mRange[1] - mRange[0]) + mRange[0];

        mValue = min(max(value, mRange[0]), mRange[1]);

        if (mCallback)
            mCallback(mValue);

        return true;
    }

    override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
    {
        if (!mEnabled)
            return false;

        requestFocus();

        immutable float kr = cast(int)(mSize.y * 0.4f), kshadow = 3;
        immutable float startX = kr + kshadow + mPos.x - 1;
        immutable float widthX = mSize.x - 2 * (kr + kshadow);

        float value = (p.x - startX) / widthX;
        value = value * (mRange[1] - mRange[0]) + mRange[0];

        mValue = min(max(value, mRange[0]), mRange[1]);

        if (mCallback)
            mCallback(mValue);

        if (mFinalCallback && down)
            mFinalCallback(mValue);

        return true;
    }

    override bool scrollEvent(Vector2i p, Vector2f rel)
    {
        if (rel.x < 0 || rel.y < 0)
        {
            if (mValue < mRange[1])
            {
                mValue += 0.01;
                mValue = min(max(value, mRange[0]), mRange[1]);
                
                if (mCallback)
                    mCallback(mValue);

                if (mFinalCallback)
                    mFinalCallback(mValue);
            }
            return true;
        } 
        else if (rel.x > 0 || rel.y > 0)
        {
            if (mValue > mRange[0])
            {
                mValue -= 0.01;
                mValue = min(max(value, mRange[0]), mRange[1]);

                if (mCallback)
                    mCallback(mValue);

                if (mFinalCallback)
                    mFinalCallback(mValue);
            }
            return true;
        }

        return super.scrollEvent(p, rel);
    }

    override bool keyboardEvent(int key, int scancode, KeyAction action, int modifiers)
    {
        if (!mEnabled)
            return false;
        
        if (action == KeyAction.Press || action == KeyAction.Repeat)
        {
            switch (key)
            {
                case Key.Left:
                    if (mValue > mRange[0])
                    {
                        mValue -= 0.01;
                        mValue = min(max(value, mRange[0]), mRange[1]);

                        if (mCallback)
                            mCallback(mValue);

                        if (mFinalCallback)
                            mFinalCallback(mValue);
                    }
                    return true;

                case Key.Right:
                    if (mValue < mRange[1])
                    {
                        mValue += 0.01;
                        mValue = min(max(value, mRange[0]), mRange[1]);
                        
                        if (mCallback)
                            mCallback(mValue);

                        if (mFinalCallback)
                            mFinalCallback(mValue);
                    }
                    return true;

                default:
                    break;
            }
        }

        return false;
    }

protected:
    float mValue;
    void delegate(float) mCallback;
    void delegate(float) mFinalCallback;
    Vector2f mRange;
    Vector2f mHighlightedRange;
    Color mHighlightColor;
}
