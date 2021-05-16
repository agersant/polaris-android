package agersant.polaris.features.player

import agersant.polaris.CollectionItem
import agersant.polaris.R
import agersant.polaris.databinding.ViewSongDetailsBinding
import agersant.polaris.util.formatTime
import android.content.Context
import android.os.Handler
import android.view.LayoutInflater
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.core.view.isVisible

fun Context.showDetailsDialog(item: CollectionItem): AlertDialog {
    val inflater = LayoutInflater.from(this)
    val detailsBinding = ViewSongDetailsBinding.inflate(inflater).apply {
        scrollView.setOnScrollChangeListener { v, _, _, _, _ ->
            topDivider.isVisible = (v.canScrollVertically(-1))
            bottomDivider.isVisible = (v.canScrollVertically(1))
        }

        val unknown by lazy { getString(R.string.details_unknown) }
        fun TextView.display(value: String?) {
            if (value != null) {
                text = value
            } else {
                isEnabled = false
                text = unknown
            }
        }

        fun TextView.display(value: Int) {
            if (value != -1) {
                text = value.toString()
            } else {
                isEnabled = false
                text = unknown
            }
        }

        title.display(item.title)
        album.display(item.album)
        artist.display(item.artist)
        albumArtist.display(item.albumArtist)
        year.display(item.year)
        trackNumber.display(item.trackNumber)
        discNumber.display(item.discNumber)
        duration.text = if (item.duration != -1) {
            formatTime(item.duration)
        } else {
            duration.isEnabled = false
            unknown
        }
    }

    val dialog = AlertDialog.Builder(this)
        .setTitle(R.string.details)
        .setView(detailsBinding.root)
        .setPositiveButton(android.R.string.ok, null)
        .create()

    Handler(mainLooper).post {
        detailsBinding.topDivider.isVisible = detailsBinding.scrollView.canScrollVertically(-1)
        detailsBinding.bottomDivider.isVisible = detailsBinding.scrollView.canScrollVertically(1)
    }

    dialog.show()

    return dialog
}
