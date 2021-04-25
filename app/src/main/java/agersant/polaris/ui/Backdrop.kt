package agersant.polaris.ui

import agersant.polaris.R
import android.content.Context
import android.graphics.Outline
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.view.*
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.appcompat.widget.Toolbar
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.content.ContextCompat
import androidx.customview.widget.Openable
import androidx.dynamicanimation.animation.DynamicAnimation
import androidx.dynamicanimation.animation.SpringAnimation
import androidx.dynamicanimation.animation.SpringForce
import androidx.navigation.NavController

class BackdropLayout(context: Context, attrs: AttributeSet? = null) : ConstraintLayout(context, attrs) {

    inner class OverlayView(context: Context) : View(context) {
        init {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            alpha = 0f
            visibility = GONE
            z = 100f
            background = ContextCompat.getDrawable(context, R.drawable.content_background)

            setOnClickListener { backdropMenu?.close() }
        }
    }

    private var backdropMenu: BackdropMenu? = null
    private var outlineRadius = 0f
    private val backdropOverlay = OverlayView(context)


    init {
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

    fun attachBackdropMenu(backdropMenu: BackdropMenu) {
        this.backdropMenu = backdropMenu
    }

    fun updatePos(interpolatedValue: Float) {
        backdropOverlay.visibility = if (interpolatedValue == 0f) GONE
        else VISIBLE

        backdropOverlay.alpha = interpolatedValue * 0.5f
    }
}

class BackdropMenu(context: Context, attrs: AttributeSet? = null) : LinearLayout(context, attrs), Openable {

    private var isOpen = false
    private var toolbar: Toolbar? = null
    private var toolbarIcon: Drawable? = null

    private var backdropLayoutId: Int? = null
    private val backdropLayout: BackdropLayout? by lazy {
        backdropLayoutId ?: return@lazy null
        val layout: BackdropLayout? = rootView.findViewById(backdropLayoutId!!)
        layout?.attachBackdropMenu(this)
        layout
    }

    init {
        alpha = 0f

        val arr = context.obtainStyledAttributes(attrs, R.styleable.BackdropMenu)
        backdropLayoutId = arr.getResourceId(R.styleable.BackdropMenu_backdropLayout, -1)
        arr.recycle()
    }

    fun setUpWith(navController: NavController, toolbar: Toolbar) {
        this.toolbar = toolbar
        navController.addOnDestinationChangedListener { _, _, _ ->
            close()
        }
    }

    private val springAnim: SpringAnimation by lazy {
        SpringAnimation(backdropLayout, DynamicAnimation.TRANSLATION_Y, 0f).apply {
            spring.dampingRatio = SpringForce.DAMPING_RATIO_NO_BOUNCY
            spring.stiffness = 500f
            addUpdateListener { _, value, _ -> updatePos(value / measuredHeight) }
        }
    }

    override fun isOpen(): Boolean {
        return isOpen
    }

    override fun open() {
        if (isOpen) {
            animateClose()
        } else {
            animateOpen()
        }
    }

    override fun close() {
        if (isOpen) animateClose()
    }

    private fun animateOpen() {
        toolbarIcon = toolbar?.navigationIcon
        toolbar?.setNavigationIcon(R.drawable.ic_close)
        isOpen = true

        springAnim.animateToFinalPosition(measuredHeight.toFloat())
    }

    private fun animateClose() {
        toolbarIcon?.let { toolbar?.navigationIcon = it }
        isOpen = false

        springAnim.animateToFinalPosition(0f)
    }

    private fun updatePos(interpolatedValue: Float) {
        visibility = if (interpolatedValue == 0f) GONE
        else View.VISIBLE

        alpha = interpolatedValue
        backdropLayout?.updatePos(interpolatedValue)
    }
}
