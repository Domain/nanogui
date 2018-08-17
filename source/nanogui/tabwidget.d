///
module nanogui.tabwidget;

import nanogui.widget;
import nanogui.tabheader;
import nanogui.stackedwidget;
import nanogui.common : Vector2i;

class TabWidget : Widget
{
public:
    this(Widget parent)
    {
        super(parent);

        mHeader = new TabHeader(null);
        mContent = new StackedWidget(null);

        super.addChild(tabCount, mHeader);
        super.addChild(tabCount, mContent);

        mHeader.callback((int i) {
            mContent.selectedIndex = i;
            if (mCallback)
                mCallback(i);
        });
    }

    /**
     * \brief Forcibly prevent mis-use of the class by throwing an exception.
     *        Children are not to be added directly to the TabWidget, see
     *        the class level documentation (\ref TabWidget) for an example.
     *
     * \throws std::runtime_error
     *     An exception is always thrown, as children are not allowed to be
     *     added directly to this Widget.
     */
    override void addChild(int index, Widget widget)
    {
        // there may only be two children: mHeader and mContent, created in the constructor
        throw new Error(
            "TabWidget: do not add children directly to the TabWidget, create tabs " ~
            "and add children to the tabs.  See TabWidget class documentation for " ~
            "example usage."
        );
    }

    final void activeTab(int tabIndex)
    {
        mHeader.activeTab = tabIndex;
        mContent.selectedIndex = tabIndex;
    }

    final int activeTab() const
    {
        assert(mHeader.activeTab == mContent.selectedIndex);
        return mContent.selectedIndex;
    }

    final int tabCount() const
    {
        assert(mContent.childCount == mHeader.tabCount);
        return mHeader.tabCount;
    }

    /**
     * Sets the callable objects which is invoked when a tab is changed.
     * The argument provided to the callback is the index of the new active tab.
     */
    final void callback(void delegate(int) callback) { mCallback = callback; };
    final void delegate(int) callback() const { return mCallback; }

    /// Creates a new tab with the specified name and returns a pointer to the layer.
    final Widget createTab(string label)
    {
        return createTab(tabCount, label);
    }

    final Widget createTab(int index, string label)
    {
        Widget tab = new Widget(null);
        addTab(index, label, tab);
        return tab;
    }

    /// Inserts a tab at the end of the tabs collection and associates it with the provided widget.
    final void addTab(string label, Widget tab)
    {
        addTab(tabCount, label, tab);
    }

    /// Inserts a tab into the tabs collection at the specified index and associates it with the provided widget.
    final void addTab(int index, string label, Widget tab)
    {
        assert(index <= tabCount);
        // It is important to add the content first since the callback
        // of the header will automatically fire when a new tab is added.
        mContent.addChild(index, tab);
        mHeader.addTab(index, label);
        assert(mHeader.tabCount == mContent.childCount);
    }

    /**
     * Removes the tab with the specified label and returns the index of the label.
     * Returns whether the removal was successful.
     */
    final bool removeTab(string label)
    {
        int index = mHeader.removeTab(label);
        if (index == -1)
            return false;
        mContent.removeChild(index);
        return true;
    }

    /// Removes the tab with the specified index.
    final void removeTab(int index)
    {
        assert(mContent.childCount < index);
        mHeader.removeTab(index);
        mContent.removeChild(index);
        if (activeTab == index)
            activeTab = index == (index - 1) ? index - 1 : 0;
    }

    /// Retrieves the label of the tab at a specific index.
    final string tabLabelAt(int index) const
    {
        return mHeader.tabLabelAt(index);
    }

    /**
     * Retrieves the index of a specific tab using its tab label.
     * Returns -1 if there is no such tab.
     */
    final int tabLabelIndex(string label)
    {
        return mHeader.tabIndex(label);
    }

    /**
     * Retrieves the index of a specific tab using a widget pointer.
     * Returns -1 if there is no such tab.
     */
    final int tabIndex(Widget tab)
    {
        return mContent.childIndex(tab);
    }

    /**
     * This function can be invoked to ensure that the tab with the provided
     * index the is visible, i.e to track the given tab. Forwards to the tab
     * header widget. This function should be used whenever the client wishes
     * to make the tab header follow a newly added tab, as the content of the
     * new tab is made visible but the tab header does not track it by default.
     */
    final void ensureTabVisible(int index)
    {
        if (!mHeader.isTabVisible(index))
            mHeader.ensureTabVisible(index);
    }

    /**
     * \brief Returns a ``const`` pointer to the Widget associated with the
     *        specified label.
     *
     * \param label
     *     The label used to create the tab.
     *
     * \return
     *     The Widget associated with this label, or ``nullptr`` if not found.
     */
    /*final const Widget tab(string label) const
    {
        int index = mHeader.tabIndex(label);
        if (index == -1 || index == mContent.childCount)
            return null;
        return mContent.children[index]; 
    }*/

    /**
     * \brief Returns a pointer to the Widget associated with the specified label.
     *
     * \param label
     *     The label used to create the tab.
     *
     * \return
     *     The Widget associated with this label, or ``nullptr`` if not found.
     */
    final Widget tab(string label)
    {
        int index = mHeader.tabIndex(label);
        if (index == -1 || index == mContent.childCount)
            return null;
        return mContent.children[index]; 
    }

    /**
     * \brief Returns a ``const`` pointer to the Widget associated with the
     *        specified index.
     *
     * \param index
     *     The current index of the desired Widget.
     *
     * \return
     *     The Widget at the specified index, or ``nullptr`` if ``index`` is not
     *     a valid index.
     */
    /*final const Widget tab(int index) const
    {
        if (index < 0 || index >= mContent.childCount)
            return null;
        return mContent.children[index];
    }*/

    /**
     * \brief Returns a pointer to the Widget associated with the specified index.
     *
     * \param index
     *     The current index of the desired Widget.
     *
     * \return
     *     The Widget at the specified index, or ``nullptr`` if ``index`` is not
     *     a valid index.
     */
    final Widget tab(int index)
    {
        if (index < 0 || index >= mContent.childCount)
            return null;
        return mContent.children[index];
    }

    override void performLayout(NVGContext nvg)
    {
        int headerHeight = mHeader.preferredSize(nvg).y;
        int margin = mTheme.mTabInnerMargin;
        mHeader.position = Vector2i(0, 0);
        mHeader.size = Vector2i(mSize.x, headerHeight);
        mHeader.performLayout(nvg);
        mContent.position = Vector2i(margin, headerHeight + margin);
        mContent.size = Vector2i(mSize.x - 2 * margin, mSize.y - 2*margin - headerHeight);
        mContent.performLayout(nvg);
    }

    override Vector2i preferredSize(NVGContext nvg) const
    {
        auto contentSize = mContent.preferredSize(nvg);
        auto headerSize = mHeader.preferredSize(nvg);
        int margin = mTheme.mTabInnerMargin;
        auto borderSize = Vector2i(2 * margin, 2 * margin);
        Vector2i tabPreferredSize = contentSize + borderSize + Vector2i(0, headerSize.y);
        return tabPreferredSize;
    }

    override void draw(NVGContext nvg)
    {
        int tabHeight = mHeader.preferredSize(nvg).y;
        auto activeArea = mHeader.activeButtonArea();


        for (int i = 0; i < 3; ++i) {
            nvg.save();
            if (i == 0)
                nvg.intersectScissor(mPos.x, mPos.y, activeArea[0].x + 1, mSize.y);
            else if (i == 1)
                nvg.intersectScissor(mPos.x + activeArea[1].x, mPos.y, mSize.x - activeArea[1].x, mSize.y);
            else
                nvg.intersectScissor(mPos.x, mPos.y + tabHeight + 2, mSize.x, mSize.y);

            nvg.beginPath();
            nvg.strokeWidth(1.0f);
            nvg.roundedRect(mPos.x + 0.5f, mPos.y + tabHeight + 1.5f, mSize.x - 1,
                        mSize.y - tabHeight - 2, mTheme.mButtonCornerRadius);
            nvg.strokeColor(mTheme.mBorderLight);
            nvg.stroke();

            nvg.beginPath();
            nvg.roundedRect(mPos.x + 0.5f, mPos.y + tabHeight + 0.5f, mSize.x - 1,
                        mSize.y - tabHeight - 2, mTheme.mButtonCornerRadius);
            nvg.strokeColor(mTheme.mBorderDark);
            nvg.stroke();
            nvg.restore();
        }

        super.draw(nvg);
    }

private:
    TabHeader mHeader;
    StackedWidget mContent;
    void delegate(int) mCallback;
}