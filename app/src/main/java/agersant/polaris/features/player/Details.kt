package agersant.polaris.features.player

import agersant.polaris.CollectionItem
import agersant.polaris.R
import agersant.polaris.databinding.ViewPlayerDetailsBinding
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
    detailsBinding.duration.text = getString(R.string.player_unknown) // TODO: get duration property from server
    detailsBinding.year.text = getString(R.string.player_unknown) // TODO: get year property from server

    AlertDialog.Builder(requireContext())
        .setTitle(R.string.player_details)
        .setView(detailsBinding.root)
        .show()
}
