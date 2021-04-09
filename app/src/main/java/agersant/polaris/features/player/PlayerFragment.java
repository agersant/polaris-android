package agersant.polaris.features.player;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.google.android.material.progressindicator.CircularProgressIndicator;
import com.google.android.material.slider.Slider;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisPlayer;
import agersant.polaris.PolarisState;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.databinding.FragmentPlayerBinding;


public class PlayerFragment extends Fragment {

    private boolean seeking = false;
    private BroadcastReceiver receiver;
    private FragmentPlayerBinding binding;
    private ImageView artwork;
    private TextView titleText;
    private TextView albumText;
    private TextView artistText;
    private ImageView pauseToggle;
    private ImageView skipNext;
    private ImageView skipPrevious;
    private TextView positionText;
    private TextView durationText;
    private Slider seekBar;
    private Handler seekBarUpdateHandler;
    private Runnable updateSeekBar;
    private CircularProgressIndicator buffering;
    private API api;
    private PolarisPlayer player;
    private PlaybackQueue playbackQueue;

    private void subscribeToEvents() {
        final PlayerFragment that = this;
        IntentFilter filter = new IntentFilter();
        filter.addAction(PolarisPlayer.PLAYING_TRACK);
        filter.addAction(PolarisPlayer.PAUSED_TRACK);
        filter.addAction(PolarisPlayer.RESUMED_TRACK);
        filter.addAction(PolarisPlayer.COMPLETED_TRACK);
        filter.addAction(PolarisPlayer.OPENING_TRACK);
        filter.addAction(PolarisPlayer.BUFFERING);
        filter.addAction(PolarisPlayer.NOT_BUFFERING);
        filter.addAction(PlaybackQueue.CHANGED_ORDERING);
        filter.addAction(PlaybackQueue.QUEUED_ITEM);
        filter.addAction(PlaybackQueue.QUEUED_ITEMS);
        filter.addAction(PlaybackQueue.REMOVED_ITEM);
        filter.addAction(PlaybackQueue.REMOVED_ITEMS);
        filter.addAction(PlaybackQueue.REORDERED_ITEMS);
        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                switch (intent.getAction()) {
                    case PolarisPlayer.OPENING_TRACK:
                    case PolarisPlayer.BUFFERING:
                    case PolarisPlayer.NOT_BUFFERING:
                        that.updateBuffering();
                    case PolarisPlayer.PLAYING_TRACK:
                        that.updateContent();
                        that.updateControls();
                        break;
                    case PolarisPlayer.PAUSED_TRACK:
                    case PolarisPlayer.RESUMED_TRACK:
                    case PolarisPlayer.COMPLETED_TRACK:
                    case PlaybackQueue.CHANGED_ORDERING:
                    case PlaybackQueue.REMOVED_ITEM:
                    case PlaybackQueue.REMOVED_ITEMS:
                    case PlaybackQueue.REORDERED_ITEMS:
                    case PlaybackQueue.QUEUED_ITEM:
                    case PlaybackQueue.QUEUED_ITEMS:
                    case PlaybackQueue.OVERWROTE_QUEUE:
                        that.updateControls();
                        break;
                }
            }
        };
        requireActivity().registerReceiver(receiver, filter);
    }

    private void scheduleSeekBarUpdates() {
        updateSeekBar = () -> {
            float duration = player.getDuration() / 1000f;
            float position = Math.min(player.getCurrentPosition() / 1000f, duration);
            float relativePosition = position / duration;

            if (!seeking) seekBar.setValue(relativePosition);
            durationText.setText(formatTime((int) duration));
            positionText.setText(formatTime((int) position));
            seekBarUpdateHandler.postDelayed(updateSeekBar, 20/*ms*/);
        };
        seekBarUpdateHandler.post(updateSeekBar);
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        setHasOptionsMenu(true);

        PolarisState state = PolarisApplication.getState();
        api = state.api;
        player = state.player;
        playbackQueue = state.playbackQueue;
        seekBarUpdateHandler = new Handler();

        binding = FragmentPlayerBinding.inflate(inflater);
        artwork = binding.artwork;
        titleText = binding.controls.title;
        albumText = binding.controls.album;
        artistText = binding.controls.artist;
        pauseToggle = binding.controls.play;
        skipNext = binding.controls.next;
        skipPrevious = binding.controls.previous;
        positionText = binding.controls.position;
        durationText = binding.controls.duration;
        seekBar = binding.controls.seekBar;
        buffering = binding.controls.buffering;

        seekBar.addOnSliderTouchListener(new Slider.OnSliderTouchListener() {
            @Override
            public void onStartTrackingTouch(@NonNull Slider slider) {
                seeking = true;
            }

            @Override
            public void onStopTrackingTouch(@NonNull Slider slider) {
                player.seekToRelative(slider.getValue() / slider.getValueTo());
                updateControls();
                seeking = false;
            }
        });
        seekBar.setLabelFormatter((value) -> formatTime((int) (value * player.getDuration() / 1000f)));

        skipPrevious.setOnClickListener((view) -> player.skipPrevious());
        skipNext.setOnClickListener((view) -> player.skipNext());
        pauseToggle.setOnClickListener((view) -> {
            if (player.isPlaying()) {
                player.pause();
            } else {
                player.resume();
            }
        });

        refresh();

        return binding.getRoot();
    }

    @Override
    public void onStart() {
        subscribeToEvents();
        scheduleSeekBarUpdates();
        super.onStart();
    }

    @Override
    public void onStop() {
        requireActivity().unregisterReceiver(receiver);
        receiver = null;
        super.onStop();
    }

    @Override
    public void onResume() {
        super.onResume();
        refresh();
    }

    private void refresh() {
        updateContent();
        updateControls();
        updateBuffering();
    }

    private void updateContent() {
        CollectionItem currentItem = player.getCurrentItem();
        if (currentItem != null) {
            populateWithTrack(currentItem);
        }
    }

    private void updateControls() {
        final float disabledAlpha = 0.2f;

        if (player.isPlaying() && !player.isIdle()) {
            pauseToggle.setImageResource(R.drawable.ic_pause_black_24dp);
        } else {
            pauseToggle.setImageResource(R.drawable.ic_play_arrow_black_24dp);
        }
        if (player.isIdle()) {
            pauseToggle.setClickable(true);
            pauseToggle.setAlpha(disabledAlpha);
        } else {
            pauseToggle.setClickable(true);
            pauseToggle.setAlpha(1f);
        }

        if (playbackQueue.hasNextTrack(player.getCurrentItem())) {
            skipNext.setClickable(true);
            skipNext.setAlpha(1.0f);
        } else {
            skipNext.setClickable(false);
            skipNext.setAlpha(disabledAlpha);
        }

        if (playbackQueue.hasPreviousTrack(player.getCurrentItem())) {
            skipPrevious.setClickable(true);
            skipPrevious.setAlpha(1.0f);
        } else {
            skipPrevious.setClickable(false);
            skipPrevious.setAlpha(disabledAlpha);
        }
    }

    private void updateBuffering() {
        if (player.isPlaying() && (player.isOpeningSong() || player.isBuffering())) {
            buffering.show();
            positionText.setVisibility(View.INVISIBLE);
        } else {
            buffering.hide();
            positionText.setVisibility(View.VISIBLE);
        }
    }

    private void populateWithTrack(CollectionItem item) {
        assert item != null;

        String title = item.getTitle();
        if (title != null) {
            titleText.setText(title);
        }
        String album = item.getAlbum();
        if (album != null) {
            albumText.setText(album);
        }

        String artist = item.getArtist();
        if (artist != null) {
            artistText.setText(artist);
        }

        String artworkPath = item.getArtwork();
        if (artworkPath != null) {
            api.loadImageIntoView(item, artwork);
        } else {
            artwork.setImageResource(R.drawable.ic_fallback_artwork);
        }
    }

    private String formatTime(int time) {
        int minutes = time / 60;
        int seconds = time % 60;

        return minutes + ":" + String.format("%02d", seconds);
    }
}
