package agersant.polaris.features.queue;

import android.content.Context;
import android.content.res.TypedArray;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.widget.FrameLayout;

import agersant.polaris.R;

public class QueueItemView extends FrameLayout {

	private static final int[] IS_PLAYING = {R.attr.state_is_playing};
	private boolean isPlaying = false;

	public QueueItemView(Context context) {
		super(context);
		fill();
	}

	public QueueItemView(Context context, AttributeSet attrs) {
		super(context, attrs);
		readAttributes(context, attrs);
		fill();

	}

	public QueueItemView(Context context, AttributeSet attrs, int defStyleAttr) {
		super(context, attrs, defStyleAttr);
		readAttributes(context, attrs);
		fill();
	}

	private void fill() {
		LayoutInflater inflater = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		inflater.inflate(R.layout.view_queue_item, this, true);
	}

	private void readAttributes(Context context, AttributeSet attrs) {
		TypedArray arr = context.obtainStyledAttributes(attrs, R.styleable.QueueItemView);
		boolean isPlayingArg = arr.getBoolean(R.styleable.QueueItemView_state_is_playing, true);
		setIsPlaying(isPlayingArg);
		arr.recycle();
	}

	@Override
	protected int[] onCreateDrawableState(int extraSpace) {
		final int[] drawableState = super.onCreateDrawableState(extraSpace + 1);
		if (isPlaying) {
			mergeDrawableStates(drawableState, IS_PLAYING);
		}
		return drawableState;
	}

	public void setIsPlaying(boolean isPlaying) {
		this.isPlaying = isPlaying;
		refreshDrawableState();
	}
}
