package agersant.polaris.features.browse;


import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.ServerAPI;
import agersant.polaris.ui.NetworkImage;


public class ExplorerAlbumFragment extends ExplorerFragment {

    private ExplorerAdapter adapter;
    private ImageView artwork;
    private TextView artist;
    private TextView title;
    private ArrayList<CollectionItem> items;

    public ExplorerAlbumFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_explorer_album, container, false);
        artwork = (ImageView) view.findViewById(R.id.album_artwork);
        artist = (TextView) view.findViewById(R.id.album_artist);
        title = (TextView) view.findViewById(R.id.album_title);

        RecyclerView recyclerView = (RecyclerView) view.findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));

        ItemTouchHelper.Callback callback = new ExplorerTouchCallback();
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        adapter = new ExplorerAdapter();
        recyclerView.setAdapter(adapter);

        populate();

        return view;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        adapter = null;
        artwork = null;
        artist = null;
        title = null;
    }

    public void setItems(ArrayList<CollectionItem> items) {
        assert !items.isEmpty();
        this.items = items;
        populate();
    }

    private void populate() {
        if (items == null || adapter == null) {
            return;
        }

        adapter.setItems(items);

        CollectionItem item = items.get(0);
        String artworkPath = item.getArtwork();
        if (artworkPath != null) {
            ServerAPI serverAPI = ServerAPI.getInstance(getActivity());
            String url = serverAPI.getMediaURL(artworkPath);
            NetworkImage.load(url, artwork);
        }

        String titleString = item.getTitle();
        if (title != null) {
            title.setText(titleString);
        }

        String artistString = item.getArtist();
        if (artist != null) {
            artist.setText(artistString);
        }
    }

}
