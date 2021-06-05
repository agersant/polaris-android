package agersant.polaris.ui

import agersant.polaris.R
import agersant.polaris.util.dp
import agersant.polaris.util.getAttrColor
import android.content.Context
import android.graphics.Outline
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import androidx.appcompat.widget.Toolbar
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isVisible
import androidx.customview.widget.Openable
import androidx.dynamicanimation.animation.DynamicAnimation
import androidx.dynamicanimation.animation.SpringAnimation
import androidx.dynamicanimation.animation.SpringForce

class BackdropLayout(context: Context, attrs: AttributeSet? = null) : ConstraintLayout(context, attrs), Openable {

    private inner class OverlayView(context: Context) : View(context) {
        init {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            isVisible = false
            alpha = 0f
            z = 100f
            setBackgroundColor(context.getAttrColor(android.R.attr.colorBackground))

            setOnClickListener { close() }
        }

        fun update(interpolatedValue: Float) {
            isVisible = interpolatedValue != 0f
            alpha = interpolatedValue * 0.5f
        }
    }

    private var isOpen = false
    private var outlineRadius = 0f
    private val backdropOverlay = OverlayView(context)
    private var toolbarIcon: Drawable? = null

    private var toolbarId: Int = 0
    private val toolbar: Toolbar by lazy {
        rootView.findViewById(toolbarId)
    }

    private var backdropMenuId: Int = 0
    private val backdropMenu: View by lazy {
        rootView.findViewById(backdropMenuId)
    }

    private val springAnim: SpringAnimation = SpringAnimation(this, DynamicAnimation.TRANSLATION_Y, 0f).apply {
        spring.dampingRatio = SpringForce.DAMPING_RATIO_NO_BOUNCY
        spring.stiffness = 800f
        addUpdateListener { _, value, _ ->
            val fraction = value / backdropMenu.height
            backdropOverlay.update(fraction)
        }
        addEndListener { _, _, _, _ ->
            if (!isOpen) backdropMenu.visibility = View.INVISIBLE
        }
    }

    init {
        val arr = context.obtainStyledAttributes(attrs, R.styleable.BackdropLayout)
        backdropMenuId = arr.getResourceId(R.styleable.BackdropLayout_backdropMenu, -1)
        toolbarId = arr.getResourceId(R.styleable.BackdropLayout_toolbar, -1)
        outlineRadius = arr.getDimension(R.styleable.BackdropLayout_cornerRadius, 16.dp)
        arr.recycle()

        outlineProvider = object : ViewOutlineProvider() {
            override fun getOutline(view: View, outline: Outline) {
                outline.setRoundRect(0, 0, width, height + outlineRadius.toInt(), outlineRadius)
            }
        }
        clipToOutline = true

        addView(backdropOverlay)
    }

    override fun isOpen(): Boolean = isOpen

    override fun open() {
        if (isOpen) {
            closeInternal()
        } else {
            openInternal()
        }
    }

    private fun openInternal() {
        if (!isOpen) {
            toolbarIcon = toolbar.navigationIcon
            toolbar.setNavigationIcon(R.drawable.ic_close)
        }

        springAnim.animateToFinalPosition(backdropMenu.height.toFloat())

        backdropMenu.visibility = View.VISIBLE
        isOpen = true
    }

    override fun close() {
        if (isOpen) closeInternal()
    }

    private fun closeInternal() {
        if (isOpen) {
            toolbarIcon?.let { toolbar.navigationIcon = it }
        }

        springAnim.animateToFinalPosition(0f)

        isOpen = false
    }
}
