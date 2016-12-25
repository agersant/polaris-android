package agersant.polaris.features.browse;

import android.view.View;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;

/**
 * Created by agersant on 12/11/2016.
 */

class BrowseItemHolderAlbum extends BrowseItemHolder {

	private TextView trackNumberText;
	private TextView titleText;

	BrowseItemHolderAlbum(BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(adapter, itemView, itemQueueStatusView);
		trackNumberText = (TextView) itemView.findViewById(R.id.track_number);
		titleText = (TextView) itemView.findViewById(R.id.title);
	}

	@Override
	void bindItem(CollectionItem item) {
		super.bindItem(item);

		String title = item.getTitle();
		if (title != null) {
			titleText.setText(title);
		} else {
			titleText.setText(item.getName());
		}

		Integer trackNumber = item.getTrackNumber();
		if (trackNumber != null) {
			trackNumberText.setText(String.format("%1$02d.", trackNumber));
		} else {
			trackNumberText.setText("");
		}
	}

}
