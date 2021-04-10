package agersant.polaris.features.player

import agersant.polaris.PlaybackQueue
import agersant.polaris.PolarisApplication
import agersant.polaris.PolarisPlayer
import agersant.polaris.R
import agersant.polaris.api.API
import agersant.polaris.databinding.FragmentPlayerBinding
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.google.android.material.progressindicator.CircularProgressIndicator
import com.google.android.material.slider.Slider
import kotlin.math.roundToInt

class PlayerFragment : Fragment() {
    private var seeking = false
    private var receiver: BroadcastReceiver? = null
    private lateinit var binding: FragmentPlayerBinding
    private lateinit var artwork: ImageView
    private lateinit var titleText: TextView
    private lateinit var albumText: TextView
    private lateinit var artistText: TextView
    private lateinit var pauseToggle: ImageView
    private lateinit var skipNext: ImageView
    private lateinit var skipPrevious: ImageView
    private lateinit var positionText: TextView
    private lateinit var durationText: TextView
    private lateinit var seekBar: Slider
    private lateinit var buffering: CircularProgressIndicator
    private lateinit var details: ImageView
    private lateinit var seekBarUpdateHandler: Handler
    private lateinit var updateSeekBar: Runnable
    private lateinit var api: API
    private lateinit var player: PolarisPlayer
    private lateinit var playbackQueue: PlaybackQueue

    private fun subscribeToEvents() {
        val that = this
        val filter = IntentFilter()
        filter.addAction(PolarisPlayer.PLAYING_TRACK)
        filter.addAction(PolarisPlayer.PAUSED_TRACK)
        filter.addAction(PolarisPlayer.RESUMED_TRACK)
        filter.addAction(PolarisPlayer.COMPLETED_TRACK)
        filter.addAction(PolarisPlayer.OPENING_TRACK)
        filter.addAction(PolarisPlayer.BUFFERING)
        filter.addAction(PolarisPlayer.NOT_BUFFERING)
        filter.addAction(PlaybackQueue.CHANGED_ORDERING)
        filter.addAction(PlaybackQueue.QUEUED_ITEM)
        filter.addAction(PlaybackQueue.QUEUED_ITEMS)
        filter.addAction(PlaybackQueue.REMOVED_ITEM)
        filter.addAction(PlaybackQueue.REMOVED_ITEMS)
        filter.addAction(PlaybackQueue.REORDERED_ITEMS)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    PolarisPlayer.OPENING_TRACK, PolarisPlayer.BUFFERING, PolarisPlayer.NOT_BUFFERING -> {
                        that.updateBuffering()
                        that.updateContent()
                        that.updateControls()
                    }
                    PolarisPlayer.PLAYING_TRACK -> {
                        that.updateContent()
                        that.updateControls()
                    }
                    PolarisPlayer.PAUSED_TRACK, PolarisPlayer.RESUMED_TRACK, PolarisPlayer.COMPLETED_TRACK, PlaybackQueue.CHANGED_ORDERING, PlaybackQueue.REMOVED_ITEM, PlaybackQueue.REMOVED_ITEMS, PlaybackQueue.REORDERED_ITEMS, PlaybackQueue.QUEUED_ITEM, PlaybackQueue.QUEUED_ITEMS, PlaybackQueue.OVERWROTE_QUEUE -> that.updateControls()
                }
            }
        }
        requireActivity().registerReceiver(receiver, filter)
    }

    private fun scheduleSeekBarUpdates() {
        updateSeekBar = Runnable {
            val duration = player.duration / 1000f
            val position = Math.min(player.currentPosition / 1000f, duration)
            val relativePosition = if (duration != 0f) position / duration else 0f
            if (!seeking) seekBar.value = relativePosition
            durationText.text = formatTime(duration.roundToInt())
            positionText.text = formatTime(position.roundToInt())
            seekBarUpdateHandler.postDelayed(updateSeekBar, 20 /*ms*/)
        }
        seekBarUpdateHandler.post(updateSeekBar)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        setHasOptionsMenu(true)
        val state = PolarisApplication.getState()
        api = state.api
        player = state.player
        playbackQueue = state.playbackQueue
        seekBarUpdateHandler = Handler()
        binding = FragmentPlayerBinding.inflate(inflater)
        artwork = binding.artwork
        titleText = binding.controls.title
        albumText = binding.controls.album
        artistText = binding.controls.artist
        pauseToggle = binding.controls.play
        skipNext = binding.controls.next
        skipPrevious = binding.controls.previous
        positionText = binding.controls.position
        durationText = binding.controls.duration
        seekBar = binding.controls.seekBar
        buffering = binding.controls.buffering
        details = binding.controls.details

        seekBar.addOnSliderTouchListener(object : Slider.OnSliderTouchListener {
            override fun onStartTrackingTouch(slider: Slider) {
                seeking = true
            }

            override fun onStopTrackingTouch(slider: Slider) {
                player.seekToRelative(slider.value / slider.valueTo)
                updateControls()
                seeking = false
            }
        })
        seekBar.setLabelFormatter { value -> formatTime((value * player.duration / 1000f).roundToInt()) }
        skipPrevious.setOnClickListener { player.skipPrevious() }
        skipNext.setOnClickListener { player.skipNext() }
        pauseToggle.setOnClickListener {
            if (player.isPlaying) {
                player.pause()
            } else {
                player.resume()
            }
        }
        details.setOnClickListener { showDetails() }

        refresh()

        return binding.root
    }

    override fun onStart() {
        subscribeToEvents()
        scheduleSeekBarUpdates()
        super.onStart()
    }

    override fun onStop() {
        requireActivity().unregisterReceiver(receiver)
        receiver = null
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        refresh()
    }

    private fun refresh() {
        updateContent()
        updateControls()
        updateBuffering()
    }

    private fun updateContent() {
        val item = player.currentItem

        titleText.text = item?.title ?: getString(R.string.player_unknown)
        albumText.text = item?.album ?: getString(R.string.player_unknown)
        artistText.text = item?.artist ?: getString(R.string.player_unknown)

        if (item?.artwork != null) {
            api.loadImageIntoView(item, artwork)
        } else {
            artwork.setImageResource(R.drawable.ic_fallback_artwork)
        }
    }

    private fun updateControls() {
        val disabledAlpha = 0.2f
        val isNotIdle = !player.isIdle

        if (player.isPlaying && isNotIdle) {
            pauseToggle.setImageResource(R.drawable.ic_pause_24)
        } else {
            pauseToggle.setImageResource(R.drawable.ic_play_arrow_24)
        }
        pauseToggle.isClickable = isNotIdle
        pauseToggle.alpha = if (isNotIdle) 1f else disabledAlpha

        val hasNextTrack = playbackQueue.hasNextTrack(player.currentItem)
        skipNext.isClickable = hasNextTrack
        skipNext.alpha = if (hasNextTrack) 1f else disabledAlpha

        val hasPrevTrack = playbackQueue.hasPreviousTrack(player.currentItem)
        skipPrevious.isClickable = hasPrevTrack
        skipPrevious.alpha = if (hasPrevTrack) 1f else disabledAlpha

        details.isClickable = isNotIdle
        details.alpha = if (isNotIdle) 1f else disabledAlpha

        seekBar.isEnabled = isNotIdle
        positionText.isEnabled = isNotIdle
        durationText.isEnabled = isNotIdle
    }

    private fun updateBuffering() {
        if (player.isPlaying && (player.isOpeningSong || player.isBuffering)) {
            buffering.show()
            positionText.visibility = View.INVISIBLE
        } else {
            buffering.hide()
            positionText.visibility = View.VISIBLE
        }
    }

    private fun showDetails() {

    }

    private fun formatTime(time: Int): String {
        val minutes = time / 60
        val seconds = time % 60
        return minutes.toString() + ":" + String.format("%02d", seconds)
    }
}
