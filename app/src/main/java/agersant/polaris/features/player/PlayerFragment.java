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
import android.widget.SeekBar;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisPlayer;
import agersant.polaris.PolarisState;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.databinding.FragmentPlayerBinding;
import androidx.annotation.NonNull;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;


public class PlayerFragment extends Fragment {

    private boolean seeking = false;
    private BroadcastReceiver receiver;
    private FragmentPlayerBinding binding;
    private ImageView artwork;
    private ImageView pauseToggle;
    private ImageView skipNext;
    private ImageView skipPrevious;
    private SeekBar seekBar;
    private Handler seekBarUpdateHandler;
    private Runnable updateSeekBar;
    private TextView buffering;
    private Toolbar toolbar;
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
            if (!seeking) {
                int precision = 10000;
                float position = player.getPositionRelative();
                seekBar.setMax(precision);
                seekBar.setProgress((int) (precision * position));
            }
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
        pauseToggle = binding.pauseToggle;
        skipNext = binding.skipNext;
        skipPrevious = binding.skipPrevious;
        seekBar = binding.seekBar;
        buffering = binding.buffering;

        toolbar = getActivity().findViewById(R.id.toolbar);

        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            int newPosition = 0;

            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                newPosition = progress;
            }

            public void onStartTrackingTouch(SeekBar seekBar) {
                seeking = true;
            }

            public void onStopTrackingTouch(SeekBar seekBar) {
                player.seekToRelative((float) newPosition / seekBar.getMax());
                seeking = false;
                updateControls();
            }
        });

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

        int playPauseIcon = player.isPlaying() ? R.drawable.ic_pause_black_24dp : R.drawable.ic_play_arrow_black_24dp;
        pauseToggle.setImageResource(playPauseIcon);
        pauseToggle.setAlpha(player.isIdle() ? disabledAlpha : 1.f);

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
        if (player.isOpeningSong()) {
            buffering.setText(R.string.player_opening);
        } else if (player.isBuffering()) {
            buffering.setText(R.string.player_buffering);
        }
        if (player.isPlaying() && (player.isOpeningSong() || player.isBuffering())) {
            buffering.setVisibility(View.VISIBLE);
        } else {
            buffering.setVisibility(View.INVISIBLE);
        }
    }

    private void populateWithTrack(CollectionItem item) {
        assert item != null;

        String title = item.getTitle();
        if (title != null) {
            toolbar.setTitle(title);
        }

        String artist = item.getArtist();
        if (artist != null) {
            toolbar.setSubtitle(artist);
        }

        String artworkPath = item.getArtwork();
        if (artworkPath != null) {
            api.loadImageIntoView(item, artwork);
        } else {
            artwork.setImageResource(R.drawable.ic_fallback_artwork);
        }
    }
}
