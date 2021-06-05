package agersant.polaris.util

import android.content.Context
import android.content.res.Resources
import android.util.TypedValue
import androidx.annotation.ColorInt
import androidx.annotation.Dimension

fun formatTime(time: Int): String {
    val minutes = time / 60
    val seconds = time % 60
    return minutes.toString() + ":" + String.format("%02d", seconds)
}

@ColorInt
fun Context.getAttrColor(attr: Int): Int {
    val out = TypedValue()
    theme.resolveAttribute(attr, out, true)
    return out.data
}

val Number.dp: Float
    @Dimension
    get() = (this.toFloat() * Resources.getSystem().displayMetrics.density)
