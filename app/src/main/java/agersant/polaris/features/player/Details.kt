package agersant.polaris.features.player

import agersant.polaris.CollectionItem
import agersant.polaris.R
import agersant.polaris.databinding.ViewSongDetailsBinding
import agersant.polaris.util.formatTime
import android.content.Context
import android.os.Handler
import android.view.LayoutInflater
import androidx.appcompat.app.AlertDialog
import androidx.core.view.isVisible

fun Context.showDetailsDialog(item: CollectionItem): AlertDialog {
    val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
    val detailsBinding = ViewSongDetailsBinding.inflate(inflater).apply {
        scrollView.setOnScrollChangeListener { v, _, _, _, _ ->
            topDivider.isVisible = (v.canScrollVertically(-1))
            bottomDivider.isVisible = (v.canScrollVertically(1))
        }

        val unknown by lazy { getString(R.string.details_unknown) }
        title.text = item.title ?: unknown
        album.text = item.album ?: unknown
        artist.text = item.artist ?: unknown
        albumArtist.text = item.albumArtist ?: unknown
        year.text = if (item.year != -1) item.year.toString() else unknown
        trackNumber.text = if (item.trackNumber != -1) item.trackNumber.toString() else unknown
        discNumber.text = if (item.discNumber != -1) item.discNumber.toString() else unknown
        duration.text = if (item.duration != -1) {
            formatTime(item.duration)
        } else {
            unknown
        }
        path.text = item.path
    }

    val dialog = AlertDialog.Builder(this)
        .setTitle(R.string.details)
        .setView(detailsBinding.root)
        .setPositiveButton(android.R.string.ok, null)
        .create()

    Handler().post {
        detailsBinding.topDivider.isVisible = detailsBinding.scrollView.canScrollVertically(-1)
        detailsBinding.bottomDivider.isVisible = detailsBinding.scrollView.canScrollVertically(1)
    }

    dialog.show()

    return dialog
}
