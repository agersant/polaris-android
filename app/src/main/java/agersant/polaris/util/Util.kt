package agersant.polaris.util

fun formatTime(time: Int): String {
    val minutes = time / 60
    val seconds = time % 60
    return minutes.toString() + ":" + String.format("%02d", seconds)
}
