package agersant.polaris;

import android.media.AudioManager;
import android.media.MediaDataSource;
import android.media.MediaPlayer;

/**
 * Created by agersant on 12/6/2016.
 */

public class PolarisMediaPlayer
		implements
		MediaPlayer.OnPreparedListener,
		MediaPlayer.OnErrorListener,
		MediaPlayer.OnCompletionListener {

	private MediaPlayer player;
	private MediaPlayer.OnCompletionListener onCompletionListener;
	private MediaPlayer.OnErrorListener onErrorListener;
	private State state;
	private boolean pause;
	private Float seekTarget;

	PolarisMediaPlayer() {
		seekTarget = null;
		pause = false;
		state = State.IDLE;
		player = new MediaPlayer();
		player.setAudioStreamType(AudioManager.STREAM_MUSIC);
		player.setOnPreparedListener(this);
		player.setOnCompletionListener(this);
		player.setOnErrorListener(this);
	}

	@Override
	public void onCompletion(MediaPlayer mediaPlayer) {
		state = State.PLAYBACK_COMPLETED;
		if (onCompletionListener != null) {
			onCompletionListener.onCompletion(mediaPlayer);
		}
	}

	void setOnCompletionListener(MediaPlayer.OnCompletionListener listener) {
		onCompletionListener = listener;
	}

	void setOnErrorListener(MediaPlayer.OnErrorListener listener) {
		onErrorListener = listener;
	}

	@Override
	public boolean onError(MediaPlayer mediaPlayer, int what, int extra) {
		state = State.ERROR;
		if (onErrorListener != null) {
			return onErrorListener.onError(mediaPlayer, what, extra);
		}
		return false;
	}

	@Override
	public void onPrepared(MediaPlayer mediaPlayer) {
		state = State.PREPARED;

		player.start();
		state = State.STARTED;

		if (seekTarget != null) {
			seekTo(seekTarget);
			seekTarget = null;
		}

		if (pause) {
			pause();
		}
	}

	void reset() {
		state = State.IDLE;
		pause = false;
		seekTarget = null;
		player.reset();
	}

	void setDataSource(MediaDataSource media) {
		state = State.INITIALIZED;
		player.setDataSource(media);
	}

	void prepareAsync() {
		state = State.PREPARING;
		player.prepareAsync();
	}

	void pause() {
		pause = true;
		switch (state) {
			case STARTED:
				state = State.PAUSED;
				player.pause();
				break;
		}
	}

	void release() {
		player.release();
		state = State.END;
	}

	void resume() {
		pause = false;
		switch (state) {
			case PREPARED:
			case PAUSED:
			case PLAYBACK_COMPLETED:
				state = State.STARTED;
				player.start();
				if (seekTarget != null) {
					seekTo(seekTarget);
					seekTarget = null;
				}
				break;
		}
	}

	boolean isPlaying() {
		if (pause) {
			return false;
		}
		switch (state) {
			case PREPARING:
			case STARTED:
				return true;
		}
		return false;
	}

	void seekTo(float progress) {
		switch (state) {
			case IDLE:
			case INITIALIZED:
			case PREPARING:
			case PREPARED:
				seekTarget = progress;
				break;
			case STOPPED:
			case ERROR:
			case END:
				return;
			case PLAYBACK_COMPLETED:
				resume();
				// Fallthrough
			case STARTED:
			case PAUSED:
			{
				int duration = (int) (progress * player.getDuration());
				player.seekTo(duration);
			}
		}
	}

	float getProgress() {
		switch (state) {
			case IDLE:
			case INITIALIZED:
			case PREPARING:
			case PREPARED:
				if (seekTarget != null) {
					return seekTarget;
				}
				return 0.f;
			case STOPPED:
			case ERROR:
			case END:
				return 0.f;
			case PLAYBACK_COMPLETED:
				return 1.f;
			case STARTED:
			case PAUSED:
			{
				int duration = player.getDuration();
				int position = player.getCurrentPosition();
				return (float) position / duration;
			}
		}
		return 0;
	}

	private enum State {
		IDLE,
		INITIALIZED,
		PREPARING,
		PREPARED,
		STARTED,
		STOPPED,
		PAUSED,
		PLAYBACK_COMPLETED,
		END,
		ERROR,
	}

}
