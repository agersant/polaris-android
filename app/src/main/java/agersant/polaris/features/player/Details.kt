package agersant.polaris.features.player

import agersant.polaris.CollectionItem
import agersant.polaris.R
import agersant.polaris.databinding.ViewDetailsBinding
import agersant.polaris.databinding.ViewDetailsItemBinding
import agersant.polaris.util.formatTime
import android.content.Context
import android.os.Handler
import android.view.LayoutInflater
import androidx.annotation.StringRes
import androidx.appcompat.app.AlertDialog
import androidx.core.view.isVisible

fun Context.showDetailsDialog(item: CollectionItem): AlertDialog {
    val inflater = LayoutInflater.from(this)
    val detailsBinding = ViewDetailsBinding.inflate(inflater).apply {
        scrollView.setOnScrollChangeListener { v, _, _, _, _ ->
            topDivider.isVisible = (v.canScrollVertically(-1))
            bottomDivider.isVisible = (v.canScrollVertically(1))
        }

        fun addValue(@StringRes labelRes: Int, value: String?) {
            if (value != null) {
                val itemView = ViewDetailsItemBinding.inflate(inflater, detailsItems, true)
                itemView.label.text = getString(labelRes)
                itemView.value.text = value
            }
        }

        fun addValue(@StringRes labelRes: Int, value: Int) {
            if (value != -1) {
                val itemView = ViewDetailsItemBinding.inflate(inflater, detailsItems, true)
                itemView.label.text = getString(labelRes)
                itemView.value.text = value.toString()
            }
        }

        addValue(R.string.details_title, item.title)
        addValue(R.string.details_album, item.album)
        addValue(R.string.details_artist, item.artist)
        addValue(R.string.details_album_artist, item.albumArtist)
        addValue(R.string.details_year, item.year)
        addValue(R.string.details_track_number, item.trackNumber)
        addValue(R.string.details_disc_number, item.discNumber)
        if (item.duration != -1) {
            addValue(R.string.details_duration, formatTime(item.duration))
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
