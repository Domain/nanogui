///
module nanogui.graph;

import nanogui.widget;
import nanogui.common : Vector2i;

class Graph : Widget
{
public:
    this(Widget parent, string caption = "Untitled")
    {
        super(parent);
        mCaption = caption;

        mBackgroundColor = Color(20, 20, 20, 128);
        mForegroundColor = Color(255, 192, 0, 128);
        mTextColor = Color(240, 240, 240, 192);
    }

    final string caption() const { return mCaption; }
    final void caption(string caption) { mCaption = caption; }

    final string header() const { return mHeader; }
    final void header(string header) { mHeader = header; }

    final string footer() const { return mFooter; }
    final void footer(string footer) { mFooter = footer; }

    final Color backgroundColor() const { return mBackgroundColor; }
    final void backgroundColor(Color backgroundColor) { mBackgroundColor = backgroundColor; }

    final Color foregroundColor() const { return mForegroundColor; }
    final void foregroundColor(Color foregroundColor) { mForegroundColor = foregroundColor; }

    final Color textColor() const { return mTextColor; }
    final void textColor(Color textColor) { mTextColor = textColor; }

    final float[] values() { return mValues; }
    final void values(float[] values) { mValues = values; }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        return Vector2i(180, 45);
    }

    override void draw(NVGContext nvg)
    {
        super.draw(nvg);

        nvg.beginPath();
        nvg.rect(mPos.x, mPos.y, mSize.x, mSize.y);
        nvg.fillColor(mBackgroundColor);
        nvg.fill();

        if (mValues.length < 2)
            return;

        nvg.beginPath();
        nvg.moveTo(mPos.x, mPos.y+mSize.y);
        foreach (i, value; mValues) {
            float vx = mPos.x + i * mSize.x / cast(float) (mValues.length - 1);
            float vy = mPos.y + (1-value) * mSize.y;
            nvg.lineTo(vx, vy);
        }

        nvg.lineTo(mPos.x + mSize.x, mPos.y + mSize.y);
        nvg.strokeColor(Color(100, 100, 100, 255));
        nvg.stroke();
        nvg.fillColor(mForegroundColor);
        nvg.fill();

        nvg.fontFace("sans");

        if (mCaption.length > 0) {
            nvg.fontSize(14.0f);
            NVGTextAlign algn;
            algn.left = true;
            algn.top = true;
            nvg.textAlign(algn);
            nvg.fillColor(mTextColor);
            nvg.text(mPos.x + 3, mPos.y + 1, mCaption);
        }

        if (mHeader.length > 0) {
            nvg.fontSize(18.0f);
            NVGTextAlign algn;
            algn.right = true;
            algn.top = true;
            nvg.textAlign(algn);
            nvg.fillColor(mTextColor);
            nvg.text(mPos.x + mSize.x - 3, mPos.y + 1, mHeader);
        }

        if (mFooter.length > 0) {
            nvg.fontSize(15.0f);
            NVGTextAlign algn;
            algn.right = true;
            algn.bottom = true;
            nvg.textAlign(algn);
            nvg.fillColor(mTextColor);
            nvg.text(mPos.x + mSize.x - 3, mPos.y + mSize.y - 1, mFooter);
        }

        nvg.beginPath();
        nvg.rect(mPos.x, mPos.y, mSize.x, mSize.y);
        nvg.strokeColor(Color(100, 100, 100, 255));
        nvg.stroke();
    }

protected:
    string mCaption, mHeader, mFooter;
    Color mBackgroundColor, mForegroundColor, mTextColor;
    float[] mValues;
}