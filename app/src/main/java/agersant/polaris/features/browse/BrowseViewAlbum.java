package agersant.polaris.features.browse;


import android.content.Context;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;
import android.widget.ImageView;
import android.widget.TextView;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.ui.FetchImageTask;


public class BrowseViewAlbum extends BrowseViewContent {

	private BrowseAdapter adapter;
	private ImageView artwork;
	private TextView artist;
	private TextView title;

	public BrowseViewAlbum(Context context) {
		super(context);

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

		adapter = new BrowseAdapterAlbum();
		recyclerView.setAdapter(adapter);
	}

	@Override
	void setItems(ArrayList<CollectionItem> items) {
		assert !items.isEmpty();

		adapter.setItems(items);

		CollectionItem item = items.get(0);
		String artworkPath = item.getArtwork();
		if (artworkPath != null) {
			FetchImageTask.load(artworkPath, artwork);
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
