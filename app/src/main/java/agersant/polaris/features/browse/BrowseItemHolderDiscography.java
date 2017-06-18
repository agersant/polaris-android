package agersant.polaris.features.browse;

import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import junit.framework.Assert;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;


class BrowseItemHolderDiscography extends BrowseItemHolder {

	private final ImageView artwork;
	private final TextView artist;
	private final TextView album;
	private final PolarisService service;

	BrowseItemHolderDiscography(PolarisService service, BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(service, adapter, itemView, itemQueueStatusView);
		this.service = service;
		artwork = (ImageView) itemView.findViewById(R.id.artwork);
		artist = (TextView) itemView.findViewById(R.id.artist);
		album = (TextView) itemView.findViewById(R.id.album);
		itemView.setOnClickListener(this);
	}

	@Override
	void bindItem(CollectionItem item) {
		super.bindItem(item);

		String artistValue = item.getArtist();
		if (artistValue != null) {
			artist.setText(artistValue);
		}

		String albumValue = item.getAlbum();
		if (albumValue != null) {
			album.setText(albumValue);
		}

		Assert.assertNotNull(item.getArtwork());
		service.getAPI().loadImageIntoView(item, artwork);
	}
}
