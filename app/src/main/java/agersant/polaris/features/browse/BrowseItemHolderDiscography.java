package agersant.polaris.features.browse;

import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;

/**
 * Created by agersant on 12/11/2016.
 */

class BrowseItemHolderDiscography extends BrowseItemHolder {

	private ImageView artwork;
	private TextView artist;
	private TextView album;
	private PolarisService service;

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

		{
			String artistValue = item.getArtist();
			if (artistValue != null) {
				artist.setText(artistValue);
			}
		}

		{
			String albumValue = item.getAlbum();
			if (albumValue != null) {
				album.setText(albumValue);
			}
		}

		service.getAPI().getImage(item, artwork);
	}
}
