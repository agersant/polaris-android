package agersant.polaris.features.browse;


import android.view.View;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.api.API;

class BrowseItemHolderAlbumDiscHeader extends BrowseItemHolder {

	private final TextView textView;

	BrowseItemHolderAlbumDiscHeader(API api, PlaybackQueue playbackQueue, BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(api, playbackQueue, adapter, itemView, itemQueueStatusView);
		textView = (TextView) itemView.findViewById(R.id.disc);
	}

	@Override
	public void onClick(View view) {
		throw new UnsupportedOperationException();
	}

	@Override
	public void onSwiped(View view) {
		throw new UnsupportedOperationException();
	}

	@Override
	public void bindItem(CollectionItem item) {
		throw new UnsupportedOperationException();
	}

	void setDiscNumber(int number) {
		String displayText = itemView.getContext().getString(R.string.browse_disc_number, number);
		textView.setText(displayText);
	}
}
