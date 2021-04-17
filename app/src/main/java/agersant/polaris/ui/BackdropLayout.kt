package agersant.polaris.ui

import agersant.polaris.R
import android.content.Context
import android.graphics.Outline
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import androidx.appcompat.widget.Toolbar
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import androidx.customview.widget.Openable
import androidx.dynamicanimation.animation.DynamicAnimation
import androidx.dynamicanimation.animation.SpringAnimation
import androidx.dynamicanimation.animation.SpringForce

class BackdropLayout(context: Context, attrs: AttributeSet? = null) : ConstraintLayout(context, attrs), Openable {

    inner class OverlayView(context: Context) : View(context) {
        init {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            isVisible = false
            alpha = 0f
            z = 100f
            background = ContextCompat.getDrawable(context, R.drawable.content_background)

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
    private var toolbarId: Int = 0
    private var toolbarIcon: Drawable? = null
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
    }

    init {
        val arr = context.obtainStyledAttributes(attrs, R.styleable.BackdropLayout)
        backdropMenuId = arr.getResourceId(R.styleable.BackdropLayout_backdropMenu, -1)
        toolbarId = arr.getResourceId(R.styleable.BackdropLayout_toolbar, -1)
        arr.recycle()

        background = ContextCompat.getDrawable(context, R.drawable.content_background)
        outlineRadius = resources.getDimension(R.dimen.backdrop_radius)
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
            close(true)
        } else {
            open(true)
        }
    }

    fun open(animate: Boolean) {
        if (!isOpen) {
            toolbarIcon = toolbar.navigationIcon
            toolbar.setNavigationIcon(R.drawable.ic_close)
        }

        springAnim.animateToFinalPosition(backdropMenu.height.toFloat())
        if (!animate) springAnim.skipToEnd()

        isOpen = true
    }

    override fun close() {
        if (isOpen) close(true)
    }

    fun close(animate: Boolean) {
        if (isOpen) {
            toolbarIcon?.let { toolbar.navigationIcon = it }
        }

        springAnim.animateToFinalPosition(0f)
        if (!animate) springAnim.skipToEnd()

        isOpen = false
    }
}
