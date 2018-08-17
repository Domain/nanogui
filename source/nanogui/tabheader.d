///
module nanogui.tabheader;

import nanogui.widget;
import nanogui.common : Vector2i, Vector2f, MouseButton;

class TabHeader : Widget
{
public:
    this(Widget parent, string font = "sans-bold")
    {
        super(parent);
        mFont = font;
    }

    final void font(string fontName)
    {
        mFont = fontName;
    }

    final string font() const
    {
        return mFont;
    }

    final bool overflowing() const
    {
        return mOverflowing;
    }

    final void callback(void delegate(int) callback)
    {
        mCallback = callback;
    }

    final void delegate(int) callback() const
    {
        return mCallback;
    }

    final void activeTab(int tabIndex)
    {
        assert(tabIndex >= 0 && tabIndex < tabCount);
        mActiveTab = tabIndex;
        if (mCallback)
            mCallback(tabIndex);
    }

    final int activeTab() const
    {
        return mActiveTab;
    }

    final bool isTabVisible(int index) const
    {
        return index >= mVisibleStart && index < mVisibleEnd;
    }

    final int tabCount() const
    {
        return cast(int) mTabButtons.length;
    }

    /// Inserts a tab at the end of the tabs collection.
    final void addTab(string label)
    {
        addTab(tabCount(), label);
    }

    /// Inserts a tab into the tabs collection at the specified index.
    final void addTab(int index, string label)
    {
        assert(index >= 0 && index <= tabCount);
        mTabButtons = mTabButtons[0 .. index] ~ new TabButton(this, label) ~ mTabButtons[index .. $];
        activeTab = index;
    }

    /**
     * Removes the tab with the specified label and returns the index of the label.
     * Returns -1 if there was no such tab
     */
    final int removeTab(string label)
    {
        import std.algorithm.searching : countUntil;
        import std.algorithm.mutation : remove;

        auto index = cast(int)mTabButtons.countUntil!(t => t.label == label);

        if (index >= 0)
        {
            mTabButtons.remove(index);
            if (index == mActiveTab && index != 0)
            {
                activeTab = index - 1;
            }
        }

        return index;
    }

    /// Removes the tab with the specified index.
    final void removeTab(int index)
    {
        assert(index >= 0 && index < tabCount);

        import std.algorithm.mutation : remove;

        mTabButtons.remove(index);
        if (index == mActiveTab && index != 0)
        {
            activeTab = index - 1;
        }
    }

    /// Retrieves the label of the tab at a specific index.
    final string tabLabelAt(int index) const
    {
        assert(index >= 0 && index < tabCount);
        return mTabButtons[index].label;
    }

    /**
     * Retrieves the index of a specific tab label.
     * Returns the number of tabs (tabsCount) if there is no such tab.
     */
    final int tabIndex(string label) const
    {
        import std.algorithm.searching : countUntil;

        auto index = cast(int)mTabButtons.countUntil!(t => t.label == label);
        return index;
    }

    /**
     * Recalculate the visible range of tabs so that the tab with the specified
     * index is visible. The tab with the specified index will either be the
     * first or last visible one depending on the position relative to the
     * old visible range.
     */
    final void ensureTabVisible(int index)
    {
        auto visibleArea = visibleButtonArea();
        auto visibleWidth = visibleArea[1].x - visibleArea[0].x;
        int allowedVisibleWidth = mSize.x - 2 * theme.mTabControlWidth;
        assert(allowedVisibleWidth >= visibleWidth);
        assert(index >= 0 && index < cast(int) mTabButtons.length);

        // Reach the goal tab with the visible range.
        if (index < mVisibleStart)
        {
            do
            {
                --mVisibleStart;
                visibleWidth += mTabButtons[mVisibleStart].size.x;
            }
            while (index < mVisibleStart);
            while (allowedVisibleWidth < visibleWidth)
            {
                --mVisibleEnd;
                visibleWidth -= mTabButtons[mVisibleEnd].size.x;
            }
        }
        else if (index >= mVisibleEnd)
        {
            do
            {
                visibleWidth += mTabButtons[mVisibleEnd].size.x;
                ++mVisibleEnd;
            }
            while (index >= mVisibleEnd);
            while (allowedVisibleWidth < visibleWidth)
            {
                visibleWidth -= mTabButtons[mVisibleStart].size.x;
                ++mVisibleStart;
            }
        }

        // Check if it is possible to expand the visible range on either side.
        while (mVisibleStart != 0
                && mTabButtons[mVisibleStart - 1].size.x < allowedVisibleWidth - visibleWidth)
        {
            --mVisibleStart;
            visibleWidth += mTabButtons[mVisibleStart].size.x;
        }
        while (mVisibleEnd != mTabButtons.length - 1
                && mTabButtons[$ - 1].size.x < allowedVisibleWidth - visibleWidth)
        {
            visibleWidth += mTabButtons[mVisibleEnd].size.x;
            ++mVisibleEnd;
        }
    }

    /**
     * Returns a pair of Vectors describing the top left (pair.first) and the
     * bottom right (pair.second) positions of the rectangle containing the visible tab buttons.
     */
    Vector2i[2] visibleButtonArea() const
    {
        if (mVisibleStart == mVisibleEnd)
            return [Vector2i(0, 0), Vector2i(0, 0)];

        import std.algorithm.iteration : fold;

        auto width = theme.mTabControlWidth + fold!((a, b) => a + b.size.x)(mTabButtons[mVisibleStart .. mVisibleEnd], 0);
        auto topLeft = mPos + Vector2i(theme.mTabControlWidth, 0);
        auto bottomRight = mPos + Vector2i(width, mSize.y);
        return [topLeft, bottomRight];
    }

    /**
     * Returns a pair of Vectors describing the top left (pair.first) and the
     * bottom right (pair.second) positions of the rectangle containing the active tab button.
     * Returns two zero vectors if the active button is not visible.
     */
    Vector2i[2] activeButtonArea() const
    {
        if (mVisibleStart == mVisibleEnd || mActiveTab < mVisibleStart || mActiveTab >= mVisibleEnd)
            return [Vector2i(0, 0), Vector2i(0, 0)];

        import std.algorithm.iteration : fold;

        auto width = theme.mTabControlWidth + fold!((a, b) => a + b.size.x)(mTabButtons[mVisibleStart .. mActiveTab], 0);
        auto topLeft = mPos + Vector2i(width, 0);
        auto bottomRight = mPos + Vector2i(width + mTabButtons[mActiveTab].size.x, mSize.y);
        return [topLeft, bottomRight];
    }

    override void performLayout(NVGContext nvg)
    {
        super.performLayout(nvg);

        Vector2i currentPosition = Vector2i(0, 0);
        // Place the tab buttons relative to the beginning of the tab header.
        foreach (tab; mTabButtons)
        {
            auto tabPreferred = tab.preferredSize(nvg);
            if (tabPreferred.x < theme.mTabMinButtonWidth)
                tabPreferred.x = theme.mTabMinButtonWidth;
            else if (tabPreferred.x > theme.mTabMaxButtonWidth)
                tabPreferred.x = theme.mTabMaxButtonWidth;
            tab.size = tabPreferred;
            tab.calculateVisibleString(nvg);
            currentPosition.x += tabPreferred.x;
        }
        calculateVisibleEnd();
        if (mVisibleStart != 0 || mVisibleEnd != tabCount)
            mOverflowing = true;
    }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        // Set up the nvg context for measuring the text inside the tab buttons.
        nvg.fontFace = mFont;
        nvg.fontSize = fontSize;
        NVGTextAlign algn;
        algn.left = true;
        algn.top = true;
        nvg.textAlign(algn);
        Vector2i size = Vector2i(2 * theme.mTabControlWidth, 0);
        foreach (tab; mTabButtons)
        {
            auto tabPreferred = tab.preferredSize(nvg);
            if (tabPreferred.x < theme.mTabMinButtonWidth)
                tabPreferred.x = theme.mTabMinButtonWidth;
            else if (tabPreferred.x > theme.mTabMaxButtonWidth)
                tabPreferred.x = theme.mTabMaxButtonWidth;
            size.x += tabPreferred.x;

            import std.algorithm.comparison : max;

            size.y = max(size.y, tabPreferred.y);
        }
        return size;
    }

    override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
    {
        super.mouseButtonEvent(p, button, down, modifiers);
        if (button == MouseButton.Left && down)
        {
            final switch (locateClick(p))
            {
            case ClickLocation.LeftControls:
                onArrowLeft();
                return true;
            case ClickLocation.RightControls:
                onArrowRight();
                return true;
            case ClickLocation.TabButtons:
                int currentPosition = theme.mTabControlWidth;
                int endPosition = p.x;

                auto firstInvisible = mVisibleStart;
                foreach (tab; mTabButtons[mVisibleStart..mVisibleEnd])
                {
                    currentPosition += tab.size.x;
                    if (currentPosition > endPosition)
                        break;
                    firstInvisible++;
                }

                // Did not click on any of the tab buttons
                if (firstInvisible == mVisibleEnd)
                    return true;

                // Update the active tab and invoke the callback.
                activeTab = firstInvisible;
                return true;
            }
        }
        return false;
    }

    override void draw(NVGContext nvg)
    {
        // Draw controls.
        super.draw(nvg);
        if (mOverflowing)
            drawControls(nvg);

        // Set up common text drawing settings.
        nvg.fontFace = mFont;
        nvg.fontSize = fontSize;
        NVGTextAlign algn;
        algn.left = true;
        algn.top = true;
        nvg.textAlign(algn);

        auto current = mVisibleStart;
        auto last = mVisibleEnd;
        auto active = mActiveTab;
        Vector2i currentPosition = mPos + Vector2i(theme.mTabControlWidth, 0);

        // Flag to draw the active tab last. Looks a little bit better.
        bool drawActive = false;
        Vector2i activePosition = Vector2i(0, 0);

        // Draw inactive visible buttons.
        while (current != last)
        {
            if (current == active)
            {
                drawActive = true;
                activePosition = currentPosition;
            }
            else
            {
                mTabButtons[current].drawAtPosition(nvg, currentPosition, false);
            }
            currentPosition.x += mTabButtons[current].size.x;
            ++current;
        }

        // Draw active visible button.
        if (drawActive)
            mTabButtons[active].drawAtPosition(nvg, activePosition, true);
    }

private:
    /// Given the beginning of the visible tabs, calculate the end.
    void calculateVisibleEnd()
    {
        auto first = mVisibleStart;
        auto last = mTabButtons.length;
        int currentPosition = theme.mTabControlWidth;
        int lastPosition = mSize.x - theme.mTabControlWidth;

        mVisibleEnd = mVisibleStart;
        foreach (tab; mTabButtons[mVisibleStart..last])
        {
            currentPosition += tab.size.x;
            if (currentPosition > lastPosition)
                break;
            mVisibleEnd++;
        }
    }

    void drawControls(NVGContext nvg)
    {
        // Left button.
        bool active = mVisibleStart != 0;

        // Draw the arrow.
        nvg.beginPath();
        auto iconLeft = mTheme.mTabHeaderLeftIcon;
        int fontSize = mFontSize == -1 ? mTheme.mButtonFontSize : mFontSize;
        float ih = fontSize;
        ih *= icon_scale;
        nvg.fontSize = ih;
        nvg.fontFace = "icons";
        Color arrowColor;
        if (active)
            arrowColor = mTheme.mTextColor;
        else
            arrowColor = mTheme.mButtonGradientBotPushed;
        nvg.fillColor(arrowColor);

        NVGTextAlign algn;
        algn.left = true;
        algn.middle = true;
        nvg.textAlign(algn);

        float yScaleLeft = 0.5f;
        float xScaleLeft = 0.2f;
        Vector2f leftIconPos = cast(Vector2f) mPos + Vector2f(
                xScaleLeft * theme.mTabControlWidth, yScaleLeft * mSize.y);
        nvg.text(leftIconPos.x, leftIconPos.y + 1, [iconLeft]);

        // Right button.
        active = mVisibleEnd != tabCount;
        // Draw the arrow.
        nvg.beginPath();
        auto iconRight = mTheme.mTabHeaderRightIcon;
        fontSize = mFontSize == -1 ? mTheme.mButtonFontSize : mFontSize;
        ih = fontSize;
        ih *= icon_scale;
        nvg.fontSize = ih;
        nvg.fontFace = "icons";
        float rightWidth = nvg.textBounds(0, 0, [iconRight], null);
        if (active)
            arrowColor = mTheme.mTextColor;
        else
            arrowColor = mTheme.mButtonGradientBotPushed;
        nvg.fillColor(arrowColor);
        nvg.textAlign(algn);
        float yScaleRight = 0.5f;
        float xScaleRight = 1.0f - xScaleLeft - rightWidth / theme.mTabControlWidth;
        Vector2f rightIconPos = cast(Vector2f) mPos + Vector2f(mSize.x,
                mSize.y * yScaleRight) - Vector2f(
                xScaleRight * theme.mTabControlWidth + rightWidth, 0);

        nvg.text(rightIconPos.x, rightIconPos.y + 1, [iconRight]);
    }

    ClickLocation locateClick(Vector2i p)
    {
        auto leftDistance = p - mPos;
        import std.algorithm.searching : all;

        bool hitLeft = leftDistance.v[].all!"a > 0"
            && (leftDistance - Vector2i(theme.mTabControlWidth, mSize.y)).v[].all!"a < 0";
        if (hitLeft)
            return ClickLocation.LeftControls;

        auto rightDistance = p - (mPos + Vector2i(mSize.x - theme.mTabControlWidth, 0));
        bool hitRight = rightDistance.v[].all!"a >= 0"
            && (rightDistance - Vector2i(theme.mTabControlWidth, mSize.y)).v[].all!"a < 0";
        if (hitRight)
            return ClickLocation.RightControls;

        return ClickLocation.TabButtons;
    }

    void onArrowLeft()
    {
        if (mVisibleStart == 0)
            return;
        --mVisibleStart;
        calculateVisibleEnd();
    }

    void onArrowRight()
    {
        if (mVisibleEnd == tabCount())
            return;
        ++mVisibleStart;
        calculateVisibleEnd();
    }

private:
    class TabButton
    {
    public:
        immutable dots = "...";

        this(TabHeader header, string label)
        {
            mHeader = header;
            mLabel = label;
        }

        final string label() const
        {
            return mLabel;
        }

        final void label(string label) { mLabel = label; }
        final void size(Vector2i size) { mSize = size; }
        final Vector2i size() const { return mSize; }

        final Vector2i preferredSize(NVGContext nvg) const
        {
            // No need to call nvg font related functions since this is done by the tab header implementation
            float[4] bounds;
            int labelWidth = cast(int)nvg.textBounds(0, 0, mLabel, bounds);
            int buttonWidth = labelWidth + 2 * mHeader.theme.mTabButtonHorizontalPadding;
            int buttonHeight = cast(int)(bounds[3] - bounds[1] + 2 * mHeader.theme.mTabButtonVerticalPadding);
            return Vector2i(buttonWidth, buttonHeight);
        }

        final void calculateVisibleString(NVGContext nvg)
        {
            // The size must have been set in by the enclosing tab header.
            NVGTextRow!char[1] displayedText;
            nvg.textBreakLines(mLabel, mSize.x, displayedText[]);

            // Check to see if the text need to be truncated.
            if (displayedText[0].end != mLabel.length) {
                auto truncatedWidth = nvg.textBounds(0.0f, 0.0f, displayedText[0].row, null);
                auto dotsWidth = nvg.textBounds(0.0f, 0.0f, dots, null);
                while ((truncatedWidth + dotsWidth + mHeader.theme.mTabButtonHorizontalPadding) > mSize.x
                        && displayedText[0].end != displayedText[0].start) {
                    --displayedText[0].end;
                    truncatedWidth = nvg.textBounds(0.0f, 0.0f, displayedText[0].row, null);
                }

                // Remember the truncated width to know where to display the dots.
                mVisibleWidth = cast(int)truncatedWidth;
                mVisibleText.last = displayedText[0].end;
            } else {
                mVisibleText.last = -1;
                mVisibleWidth = 0;
            }
            mVisibleText.first = displayedText[0].start;
        }

        final void drawAtPosition(NVGContext nvg, Vector2i position, bool active)
        {
            int xPos = position.x;
            int yPos = position.y;
            int width = mSize.x;
            int height = mSize.y;
            auto theme = mHeader.theme;

            nvg.save();
            nvg.intersectScissor(xPos, yPos, width+1, height);
            if (!active) {
                // Background gradients
                auto gradTop = theme.mButtonGradientTopPushed;
                auto gradBot = theme.mButtonGradientBotPushed;

                // Draw the background.
                nvg.beginPath();
                nvg.roundedRect(xPos + 1, yPos + 1, width - 1, height + 1,
                            theme.mButtonCornerRadius);
                auto backgroundColor = nvg.linearGradient(xPos, yPos, xPos, yPos + height,
                                                            gradTop, gradBot);
                nvg.fillPaint(backgroundColor);
                nvg.fill();
            }

            if (active) {
                nvg.beginPath();
                nvg.strokeWidth(1.0f);
                nvg.roundedRect(xPos + 0.5f, yPos + 1.5f, width,
                            height + 1, theme.mButtonCornerRadius);
                nvg.strokeColor(theme.mBorderLight);
                nvg.stroke();

                nvg.beginPath();
                nvg.roundedRect(xPos + 0.5f, yPos + 0.5f, width,
                            height + 1, theme.mButtonCornerRadius);
                nvg.strokeColor(theme.mBorderDark);
                nvg.stroke();
            } else {
                nvg.beginPath();
                nvg.roundedRect(xPos + 0.5f, yPos + 1.5f, width,
                            height, theme.mButtonCornerRadius);
                nvg.strokeColor(theme.mBorderDark);
                nvg.stroke();
            }
            nvg.resetScissor();
            nvg.restore();

            // Draw the text with some padding
            int textX = xPos + theme.mTabButtonHorizontalPadding;
            int textY = yPos + theme.mTabButtonVerticalPadding;
            auto textColor = theme.mTextColor;
            nvg.beginPath();
            nvg.fillColor(textColor);
            if (mVisibleText.last != -1)
            {
                nvg.text(textX, textY, mLabel[mVisibleText.first..mVisibleText.last]);
                nvg.text(textX + mVisibleWidth, textY, dots);
            }
            else
            {
                nvg.text(textX, textY, mLabel);
            }
        }

        final void drawActiveBorderAt(NVGContext nvg, Vector2i position, float offset, Color color)
        {
            int xPos = position.x;
            int yPos = position.y;
            int width = mSize.x;
            int height = mSize.y;
            nvg.beginPath();
            nvg.lineJoin(NVGLineCap.Round);
            nvg.moveTo(xPos + offset, yPos + height + offset);
            nvg.lineTo(xPos + offset, yPos + offset);
            nvg.lineTo(xPos + width - offset, yPos + offset);
            nvg.lineTo(xPos + width - offset, yPos + height + offset);
            nvg.strokeColor(color);
            nvg.strokeWidth(mHeader.theme.mTabBorderWidth);
            nvg.stroke();
        }

        final void drawInactiveBorderAt(NVGContext nvg, Vector2i position, float offset, Color color)
        {
            int xPos = position.x;
            int yPos = position.y;
            int width = mSize.x;
            int height = mSize.y;
            nvg.beginPath();
            nvg.roundedRect(xPos + offset, yPos + offset, width - offset, height - offset,
                        mHeader.theme.mButtonCornerRadius);
            nvg.strokeColor(color);
            nvg.stroke();
        }

    private:
        TabHeader mHeader;
        string mLabel;
        Vector2i mSize;

        /**
         * \struct StringView tabheader.h nanogui/tabheader.h
         *
         * \brief Helper struct to represent the TabButton.
         */
        struct StringView {
            int first = 0;
            int last = 0;
        };
        StringView mVisibleText;
        int mVisibleWidth = 0;
    }

    /// The location in which the Widget will be facing.
    enum ClickLocation
    {
        LeftControls,
        RightControls,
        TabButtons
    };

private:
    void delegate(int) mCallback;
    TabButton[] mTabButtons;
    int mVisibleStart = 0;
    int mVisibleEnd = 0;
    int mActiveTab = 0;
    bool mOverflowing = false;
    string mFont;
}
