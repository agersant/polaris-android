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

        path.text = item.path
        albumArtist.text = item.albumArtist ?: getString(R.string.player_unknown)
        artist.text = item.artist ?: getString(R.string.player_unknown)
        album.text = item.album ?: getString(R.string.player_unknown)
        title.text = item.title ?: getString(R.string.player_unknown)
        discNumber.text = if (item.discNumber != -1) item.discNumber.toString() else getString(R.string.player_unknown)
        trackNumber.text = if (item.trackNumber != -1) item.trackNumber.toString() else getString(R.string.player_unknown)
        year.text = if (item.year != -1) item.year.toString() else getString(R.string.player_unknown)
        duration.text = if (item.duration != -1) {
            formatTime(item.duration)
        } else {
            getString(R.string.player_unknown)
        }
    }

    val dialog = AlertDialog.Builder(this)
        .setTitle(R.string.player_details)
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
