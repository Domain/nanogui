///
module nanogui.colorwheel;

import std.algorithm.comparison : min, max;
import std.math : sin, cos, sqrt, atan;
import nanogui.widget;
import nanogui.common : Vector2i, Vector2f, MouseButton, Color;
import arsd.nanovega : linearGradient, NVGHSL;

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
        //Color black  = Color(0.0f, 0.0f, 0.0f, 1.0f);
        //Color white  = Color(1.0f, 1.0f, 1.0f, 1.0f);
        Color result = rgb; // * (1 - mWhite - mBlack) + black * mBlack + white * mWhite;
        result.v[] *= 255f;
        return result;
    }

    /// Sets the current Color this ColorWheel has selected.
    final void color(Color rgb)
    {
        rgb.v[] /= 255f;
        auto hsv = rgb2hsv(rgb);
        mHue = hsv[0];
        mBlack = hsv[1];
        mWhite = hsv[2];

        // float r = rgb.r, g = rgb.g, b = rgb.b;


        // float max = max(r, g, b);
        // float min = min(r, g, b);
        // float l = (max + min) / 2;

        // if (max == min) {
        //     mHue = 0.0f;
        //     mBlack = 1.0f - l;
        //     mWhite = l;
        // } else {
        //     float d = max - min, h;
        //     /* float s = l > 0.5 ? d / (2 - max - min) : d / (max + min); */
        //     if (max == r)
        //         h = (g - b) / d + (g < b ? 6 : 0);
        //     else if (max == g)
        //         h = (b - r) / d + 2;
        //     else
        //         h = (r - g) / d + 4;
        //     h /= 6;

        //     mHue = h;

        //     // Eigen::Matrix<float, 4, 3> M;
        //     // M.topLeftCorner<3, 1>() = hue2rgb(h).head<3>();
        //     // M(3, 0) = 1.;
        //     // M.col(1) = Vector4f{ 0., 0., 0., 1. };
        //     // M.col(2) = Vector4f{ 1., 1., 1., 1. };

        //     // Vector4f rgb4{ rgb[0], rgb[1], rgb[2], 1. };
        //     // Vector3f bary = M.colPivHouseholderQr().solve(rgb4);

        //     // mBlack = bary[1];
        //     // mWhite = bary[2];
        // }
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
        auto sqrt3 = sqrt(3.0f);
        auto sat = mBlack;
        auto val = mWhite;
        auto X = r0 - 6 + r0 * (2 * val - sat * val - 1) * sqrt3 / 2;
        auto Y = r0 + r0 * (1 - 3 * sat * val) / 2;
        float sx = X; //r*(1 - mWhite - mBlack) + ax*mWhite + bx*mBlack;
        float sy = Y; //                          ay*mWhite + by*mBlack;

        nvg.strokeWidth(u);
        nvg.beginPath();
        nvg.circle(sx,sy,2*u);
        nvg.strokeColor(Color(255,255,255,192));
        nvg.stroke();

        nvg.restore();

        nvg.restore();
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
        // result.rgba[] *= 255f;
        // return result;
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

        auto sqrt3 = sqrt(3.0f);
        auto x1 = x / r;
        auto y1 = y / r;
        if (0 * x1 + 2 * y1 > 1) return Region.None;
        else if (sqrt3 * x1 + (-1) * y1 > 1) return Region.None;
        else if (-sqrt3 * x1 + (-1) * y1 > 1) return Region.None;
        else
        {
            // Triangle
            mBlack = (1 - 2 * y1) / (sqrt3 * x1 - y1 + 2);
            mWhite = (sqrt3 * x1 - y1 + 2) / 3;

            return Region.InnerTriangle;
        }

        // float ax = cos( 120.0f/180.0f*NVG_PI) * r;
        // float ay = sin( 120.0f/180.0f*NVG_PI) * r;
        // float bx = cos(-120.0f/180.0f*NVG_PI) * r;
        // float by = sin(-120.0f/180.0f*NVG_PI) * r;

        // // typedef Eigen::Matrix<float,2,2>        Matrix2f;

        // // Eigen::Matrix<float, 2, 3> triangle;
        // // triangle << ax,bx,r,
        // //             ay,by,0;
        // // triangle = Eigen::Rotation2D<float>(mHue * 2 * NVG_PI).matrix() * triangle;

        // // Matrix2f T;
        // // T << triangle(0,0) - triangle(0,2), triangle(0,1) - triangle(0,2),
        // //     triangle(1,0) - triangle(1,2), triangle(1,1) - triangle(1,2);
        // // Vector2f pos { x - triangle(0,2), y - triangle(1,2) };

        //  Vector2f bary = Vector2f(0, 0);//T.colPivHouseholderQr().solve(pos);
        //  float l0 = bary[0], l1 = bary[1], l2 = 1 - l0 - l1;
        // bool triangleTest = l0 >= 0 && l0 <= 1.0f && l1 >= 0.0f && l1 <= 1.0f &&
        //                     l2 >= 0.0f && l2 <= 1.0f;

        // if ((consideredRegions & Region.InnerTriangle) &&
        //     (triangleTest || consideredRegions == Region.InnerTriangle)) {
        //     if (!(consideredRegions & Region.InnerTriangle))
        //         return Region.None;
        //     l0 = min(max(0.0f, l0), 1.0f);
        //     l1 = min(max(0.0f, l1), 1.0f);
        //     l2 = min(max(0.0f, l2), 1.0f);
        //     float sum = l0 + l1 + l2;
        //     l0 /= sum;
        //     l1 /= sum;
        //     mWhite = l0;
        //     mBlack = l1;
        //     if (mCallback)
        //         mCallback(color());
        //     return Region.InnerTriangle;
        // }

        // return Region.None;
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