package agersant.polaris.features.browse;


import android.content.Context;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;
import android.widget.ImageView;
import android.widget.TextView;

import junit.framework.Assert;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;


public class BrowseViewAlbum extends BrowseViewContent {

	private final BrowseAdapter adapter;
	private final ImageView artwork;
	private final TextView artist;
	private final TextView title;
	private final PolarisService service;

	public BrowseViewAlbum(Context context) {
		super(context);
		throw new UnsupportedOperationException();
	}

	public BrowseViewAlbum(Context context, PolarisService service) {
		super(context);
		this.service = service;

		LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		inflater.inflate(R.layout.view_browse_album, this, true);

		artwork = (ImageView) findViewById(R.id.album_artwork);
		artist = (TextView) findViewById(R.id.album_artist);
		title = (TextView) findViewById(R.id.album_title);

		RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
		recyclerView.setHasFixedSize(true);
		recyclerView.setLayoutManager(new LinearLayoutManager(context));

		ItemTouchHelper.Callback callback = new BrowseTouchCallback();
		ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
		itemTouchHelper.attachToRecyclerView(recyclerView);

		adapter = new BrowseAdapterAlbum(service);
		recyclerView.setAdapter(adapter);
	}

	@Override
	void setItems(ArrayList<? extends CollectionItem> items) {
		Assert.assertFalse(items.isEmpty());

		Collections.sort(items, new Comparator<CollectionItem>() {
			@Override
			public int compare(CollectionItem a, CollectionItem b) {
				return a.getTrackNumber() - b.getTrackNumber();
			}
		});
		adapter.setItems(items);

		CollectionItem item = items.get(0);

		String artworkPath = item.getArtwork();
		if (artworkPath != null) {
			service.getAPI().loadImageIntoView(item, artwork);
		}

		String titleString = item.getAlbum();
		if (title != null) {
			title.setText(titleString);
		}

		String artistString = item.getAlbumArtist();
		if (artistString == null) {
			artistString = item.getArtist();
		}
		if (artist != null) {
			artist.setText(artistString);
		}
	}

}
