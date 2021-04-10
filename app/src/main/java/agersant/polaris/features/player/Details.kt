package agersant.polaris.features.player

import agersant.polaris.CollectionItem
import agersant.polaris.R
import agersant.polaris.databinding.ViewPlayerDetailsBinding
import agersant.polaris.util.formatTime
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment

fun Fragment.showDetails(item: CollectionItem) {
    val detailsBinding = ViewPlayerDetailsBinding.inflate(layoutInflater)

    detailsBinding.path.text = item.path
    detailsBinding.albumArtist.text = item.albumArtist ?: getString(R.string.player_unknown)
    detailsBinding.artist.text = item.artist ?: getString(R.string.player_unknown)
    detailsBinding.album.text = item.album ?: getString(R.string.player_unknown)
    detailsBinding.title.text = item.title ?: getString(R.string.player_unknown)
    detailsBinding.discNumber.text = if (item.discNumber != -1) item.discNumber.toString() else getString(R.string.player_unknown)
    detailsBinding.trackNumber.text = if (item.trackNumber != -1) item.trackNumber.toString() else getString(R.string.player_unknown)
    detailsBinding.year.text = if (item.year != -1) item.year.toString() else getString(R.string.player_unknown)
    detailsBinding.duration.text = if (item.duration != -1) {
        formatTime(item.duration)
    } else {
        getString(R.string.player_unknown)
    }

    AlertDialog.Builder(requireContext())
        .setTitle(R.string.player_details)
        .setView(detailsBinding.root)
        .show()
}
