///
module nanogui.colorwheel;

import std.algorithm.comparison : min, max;
import std.math : sin, cos, sqrt, atan;
import nanogui.widget;
import nanogui.common : Vector2i, Vector2f, MouseButton, Color;
import arsd.nanovega : linearGradient, NVGHSL;
import gfm.math.funcs;

/**
 * \class ColorWheel colorwheel.h nanogui/colorwheel.h
 *
 * \brief Fancy analog widget to select a color value.  This widget was
 *        contributed by Dmitriy Morozov.
 */
class ColorWheel : Widget
{
    /**
     * Adds a ColorWheel to the specified parent.
     *
     * \param parent
     *     The Widget to add this ColorWheel to.
     *
     * \param color
     *     The initial color of the ColorWheel (default: Red).
     */
    this(Widget parent, Color color = Color(255, 0, 0, 255))
    {
        super(parent);
        mDragRegion = Region.None;
        this.color = color;
    }

    /// The callback to execute when a user changes the ColorWheel value.
    final void delegate(Color) callback() const { return mCallback; }

    /// Sets the callback to execute when a user changes the ColorWheel value.
    final void callback(void delegate(Color) callback) { mCallback = callback; }

    /// The current Color this ColorWheel has selected.
    final Color color() const
    {
        Color rgb    = hue2rgb(mHue, mBlack, mWhite);
        rgb.v[] *= 255f;
        return rgb;
    }

    /// Sets the current Color this ColorWheel has selected.
    final void color(Color rgb)
    {
        rgb.v[] /= 255f;
        auto hsv = rgb2hsv(rgb);
        mHue = hsv[0];
        mBlack = hsv[1];
        mWhite = hsv[2];
    }

    /// The preferred size of this ColorWheel.
    override Vector2i preferredSize(NVGContext nvg) const
    {
        return Vector2i(100, 100);
    }

    /// Draws the ColorWheel.
    override void draw(NVGContext nvg)
    {
        super.draw(nvg);

        if (!mVisible)
            return;

        float x = mPos.x,
            y = mPos.y,
            w = mSize.x,
            h = mSize.y;

        int i;
        float r0, r1, ax,ay, bx,by, cx,cy, aeps, r;
        float hue = mHue;
        NVGPaint paint;

        nvg.save();

        cx = x + w*0.5f;
        cy = y + h*0.5f;
        r1 = (w < h ? w : h) * 0.5f - 5.0f;
        r0 = r1 * 0.75f;

        aeps = 0.5f / r1;   // half a pixel arc length in radians (2pi cancels out).

        for (i = 0; i < 6; i++) {
            float a0 = cast(float)i / 6.0f * NVG_PI * 2.0f - aeps;
            float a1 = cast(float)(i+1.0f) / 6.0f * NVG_PI * 2.0f + aeps;
            nvg.beginPath();
            nvg.arc(NVGWinding.CW,  cx, cy, r0, a0, a1);
            nvg.arc(NVGWinding.CCW, cx, cy, r1, a1, a0);
            nvg.closePath();
            ax = cx + cos(a0) * (r0+r1)*0.5f;
            ay = cy + sin(a0) * (r0+r1)*0.5f;
            bx = cx + cos(a1) * (r0+r1)*0.5f;
            by = cy + sin(a1) * (r0+r1)*0.5f;
            paint = nvg.linearGradient(ax, ay, bx, by,
                                    nvgHSLA(a0 / (NVG_PI * 2), 1.0f, 0.55f, 255),
                                    nvgHSLA(a1 / (NVG_PI * 2), 1.0f, 0.55f, 255));
            nvg.fillPaint(paint);
            nvg.fill();
        }

        nvg.beginPath();
        nvg.circle(cx,cy, r0-0.5f);
        nvg.circle(cx,cy, r1+0.5f);
        nvg.strokeColor(Color(0,0,0,64));
        nvg.strokeWidth(1.0f);
        nvg.stroke();

        // Selector
        nvg.save();
        nvg.translate(cx,cy);
        nvg.rotate(hue*NVG_PI*2);

        // Marker on
        float u = max(r1/50, 1.5f);
            u = min(u, 4.0f);
        nvg.strokeWidth(u);
        nvg.beginPath();
        nvg.rect(r0-1,-2*u,r1-r0+2,4*u);
        nvg.strokeColor(Color(255,255,255,192));
        nvg.stroke();

        paint = nvg.boxGradient(r0-3,-5,r1-r0+6,10, 2,4, Color(0,0,0,128), Color(0,0,0,0));
        nvg.beginPath();
        nvg.rect(r0-2-10,-4-10,r1-r0+4+20,8+20);
        nvg.rect(r0-2,-4,r1-r0+4,8);
        nvg.pathWinding(NVGSolidity.Hole);
        nvg.fillPaint(paint);
        nvg.fill();

        // Center triangle
        r = r0 - 6;
        ax = cos(120.0f/180.0f*NVG_PI) * r;
        ay = sin(120.0f/180.0f*NVG_PI) * r;
        bx = cos(-120.0f/180.0f*NVG_PI) * r;
        by = sin(-120.0f/180.0f*NVG_PI) * r;
        nvg.beginPath();
        nvg.moveTo(r,0);
        nvg.lineTo(ax, ay);
        nvg.lineTo(bx, by);
        nvg.closePath();
        paint = nvg.linearGradient(r, 0, ax, ay, nvgHSLA(hue, 1.0f, 0.5f, 255),
                                NVGColor(255, 255, 255, 255));
        nvg.fillPaint(paint);
        nvg.fill();
        paint = nvg.linearGradient((r + ax) * 0.5f, (0 + ay) * 0.5f, bx, by,
                                NVGColor(0, 0, 0, 0), NVGColor(0, 0, 0, 255));
        nvg.fillPaint(paint);
        nvg.fill();
        nvg.strokeColor(Color(0, 0, 0, 64));
        nvg.stroke();

        // Select circle on triangle
        auto pa = Vector2f(r, 0.0f);
        auto pb = Vector2f(bx, by);
        auto pc = Vector2f(ax, ay);
        auto sp = lerp(lerp(pc, pa, mBlack), pb, (1 - mWhite));

        nvg.strokeWidth(u);
        nvg.beginPath();
        nvg.circle(sp.x, sp.y, 2*u);
        nvg.strokeColor(Color(255,255,255,192));
        nvg.stroke();

        nvg.restore();

        nvg.restore();
    }

    Vector2f rotate(Vector2f v, float cos_a, float sin_a)
    {
        return Vector2f(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a);
    }

    /// Handles mouse button click events for the ColorWheel.
    override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
    {
        super.mouseButtonEvent(p, button, down, modifiers);
        if (!mEnabled || button != MouseButton.Left)
            return false;

        if (down) {
            mDragRegion = adjustPosition(p);
            return mDragRegion != Region.None;
        } else {
            mDragRegion = Region.None;
            return true;
        }
    }

    /// Handles mouse drag events for the ColorWheel.
    override bool mouseDragEvent(Vector2i p, Vector2i rel, MouseButton button, int modifiers)
    {
        return adjustPosition(p, mDragRegion) != Region.None;
    }

private:
    // Used to describe where the mouse is interacting
    enum Region {
        None = 0,
        InnerTriangle = 1,
        OuterCircle = 2,
        Both = 3
    };

    // Converts a specified hue (with saturation = value = 1) to RGB space.
    Color hue2rgb(float h, float s, float v) const
    {
        //float s = 1., v = 1.;

        if (h < 0) h += 1;

        int i = cast(int)(h * 6);
        float f = h * 6 - i;
        float p = v * (1 - s);
        float q = v * (1 - f * s);
        float t = v * (1 - (1 - f) * s);

        float r = 0, g = 0, b = 0;
        switch (i % 6) {
            case 0: r = v, g = t, b = p; break;
            case 1: r = q, g = v, b = p; break;
            case 2: r = p, g = v, b = t; break;
            case 3: r = p, g = q, b = v; break;
            case 4: r = t, g = p, b = v; break;
            case 5: r = v, g = p, b = q; break;
            default: break;
        }

        return Color(r, g, b, 1.0f);
    }

    Color rgb2hsv(Color color) const
    {
        import std.math : abs;
        import std.algorithm.mutation : swap;

        auto r = color.r;
        auto g = color.g;
        auto b = color.b;

        float K = 0.0f;
        if (g < b)
        {
            swap(g, b);
            K = -1.0f;
        }
        if (r < g)
        {
            swap(r, g);
            K = -2.0f / 6.0f - K;
        }

        Color hsv;

        const float chroma = r - (g < b ? g : b);
        hsv[0] = abs(K + (g - b) / (6.0f * chroma + 1e-20f));
        hsv[1] = chroma / (r + 1e-20f);
        hsv[2] = r;

        return hsv;
    }

    // Manipulates the positioning of the different regions of the ColorWheel.
    Region adjustPosition(const Vector2i p, Region consideredRegions = Region.Both)
    {
        float x = p.x - mPos.x,
          y = p.y - mPos.y,
          w = mSize.x,
          h = mSize.y;

        float cx = w*0.5f;
        float cy = h*0.5f;
        float r1 = (w < h ? w : h) * 0.5f - 5.0f;
        float r0 = r1 * 0.75f;

        x -= cx;
        y -= cy;

        float mr = sqrt(x*x + y*y);

        if ((consideredRegions & Region.OuterCircle) &&
            ((mr >= r0 && mr <= r1) || (consideredRegions == Region.OuterCircle))) {
            if (!(consideredRegions & Region.OuterCircle))
                return Region.None;
            mHue = atan(y / x);
            if (x < 0)
                mHue += NVG_PI;
            mHue /= 2*NVG_PI;

            if (mCallback)
                mCallback(color());

            return Region.OuterCircle;
        }

        float r = r0 - 6;

        auto pa = Vector2f(r, 0.0f);
        auto pb = Vector2f(cos(-120.0f/180.0f*NVG_PI) * r, sin(-120.0f/180.0f*NVG_PI) * r);
        auto pc = Vector2f(cos( 120.0f/180.0f*NVG_PI) * r, sin( 120.0f/180.0f*NVG_PI) * r);

        auto pt = Vector2f(x, y).rotate(-mHue * 2.0f * NVG_PI);

        import gfm.math.shapes : Triangle;

        auto sv = Triangle!(float, 2)(pa, pb, pc);
        auto inTriangle = sv.contains(pt);

        if ((consideredRegions & Region.InnerTriangle) &&
            (inTriangle || consideredRegions == Region.InnerTriangle)) {
                if (!(consideredRegions & Region.InnerTriangle))
                    return Region.None;
                //if (!sv.contains(pt))
                    //pt = sv.closestPoint(pt);
                float uu, vv, ww;
                sv.barycentricCoords(pt, uu, vv, ww);
                import gfm.math.funcs : clamp;
                mWhite = clamp(1.0f - vv, 0.0001f, 1.0f);
                mBlack = clamp(uu / mWhite, 0.0001f, 1.0f);
                if (mCallback)
                    mCallback(color());
                return Region.InnerTriangle;
            }

        return Region.None;
    }

    void ImTriangleBarycentricCoords(Vector2f a, Vector2f b, Vector2f c, Vector2f p, out float out_u, out float out_v, out float out_w)
    {
        auto v0 = b - a;
        auto v1 = c - a;
        auto v2 = p - a;
        const float denom = v0.x * v1.y - v1.x * v0.y;
        out_v = (v2.x * v1.y - v1.x * v2.y) / denom;
        out_w = (v0.x * v2.y - v2.x * v0.y) / denom;
        out_u = 1.0f - out_v - out_w;
    }

protected:
    /// The current Hue in the HSV color model.
    float mHue;

    /**
     * The implicit Value component of the HSV color model.  See implementation
     * \ref nanogui::ColorWheel::color for its usage.  Valid values are in the
     * range ``[0, 1]``.
     */
    float mWhite;

    /**
     * The implicit Saturation component of the HSV color model.  See implementation
     * \ref nanogui::ColorWheel::color for its usage.  Valid values are in the
     * range ``[0, 1]``.
     */
    float mBlack;

    /// The current region the mouse is interacting with.
    Region mDragRegion;

    /// The current callback to execute when the color value has changed.
    void delegate(Color) mCallback;
}