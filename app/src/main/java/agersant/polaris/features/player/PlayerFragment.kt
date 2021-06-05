package agersant.polaris.features.player

import agersant.polaris.PlaybackQueue
import agersant.polaris.PolarisApplication
import agersant.polaris.PolarisPlayer
import agersant.polaris.R
import agersant.polaris.api.API
import agersant.polaris.databinding.FragmentPlayerBinding
import agersant.polaris.util.formatTime
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.*
import android.widget.ImageView
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.google.android.material.progressindicator.CircularProgressIndicator
import com.google.android.material.slider.Slider
import kotlin.math.min
import kotlin.math.roundToInt

class PlayerFragment : Fragment() {
    private val viewModel: PlayerViewModel by viewModels()
    private var seeking = false
    private var receiver: BroadcastReceiver? = null
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
    private lateinit var seekBarUpdateHandler: Handler
    private lateinit var updateSeekBar: Runnable
    private lateinit var api: API
    private lateinit var player: PolarisPlayer
    private lateinit var playbackQueue: PlaybackQueue

    private fun subscribeToEvents() {
        val filter = IntentFilter().apply {
            addAction(PolarisPlayer.PLAYING_TRACK)
            addAction(PolarisPlayer.PAUSED_TRACK)
            addAction(PolarisPlayer.RESUMED_TRACK)
            addAction(PolarisPlayer.COMPLETED_TRACK)
            addAction(PolarisPlayer.OPENING_TRACK)
            addAction(PolarisPlayer.BUFFERING)
            addAction(PolarisPlayer.NOT_BUFFERING)
            addAction(PlaybackQueue.CHANGED_ORDERING)
            addAction(PlaybackQueue.QUEUED_ITEM)
            addAction(PlaybackQueue.QUEUED_ITEMS)
            addAction(PlaybackQueue.REMOVED_ITEM)
            addAction(PlaybackQueue.REMOVED_ITEMS)
            addAction(PlaybackQueue.REORDERED_ITEMS)
        }
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    PolarisPlayer.OPENING_TRACK,
                    PolarisPlayer.BUFFERING,
                    PolarisPlayer.NOT_BUFFERING -> {
                        this@PlayerFragment.updateContent()
                        this@PlayerFragment.updateControls()
                        this@PlayerFragment.updateBuffering()
                    }
                    PolarisPlayer.PLAYING_TRACK -> {
                        this@PlayerFragment.updateContent()
                        this@PlayerFragment.updateControls()
                    }
                    PolarisPlayer.PAUSED_TRACK,
                    PolarisPlayer.RESUMED_TRACK,
                    PolarisPlayer.COMPLETED_TRACK,
                    PlaybackQueue.CHANGED_ORDERING,
                    PlaybackQueue.REMOVED_ITEM,
                    PlaybackQueue.REMOVED_ITEMS,
                    PlaybackQueue.REORDERED_ITEMS,
                    PlaybackQueue.QUEUED_ITEM,
                    PlaybackQueue.QUEUED_ITEMS,
                    PlaybackQueue.OVERWROTE_QUEUE -> {
                        this@PlayerFragment.updateControls()
                    }
                }
            }
        }
        requireActivity().registerReceiver(receiver, filter)
    }

    private fun scheduleSeekBarUpdates() {
        updateSeekBar = Runnable {
            val duration = player.duration / 1000f
            val position = min(player.currentPosition / 1000f, duration)
            val relativePosition = if (duration != 0f) position / duration else 0f

            if (!seeking) seekBar.value = relativePosition
            durationText.text = formatTime(duration.roundToInt())
            positionText.text = formatTime(position.roundToInt())
            seekBarUpdateHandler.postDelayed(updateSeekBar, 20 /*ms*/)
        }
        seekBarUpdateHandler.post(updateSeekBar)
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        setHasOptionsMenu(true)

        val state = PolarisApplication.getState()
        api = state.api
        player = state.player
        playbackQueue = state.playbackQueue
        seekBarUpdateHandler = Handler(Looper.getMainLooper())

        val binding = FragmentPlayerBinding.inflate(inflater)
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

        if (viewModel.detailsShowing) {
            showDetails()
        }

        return binding.root
    }

    override fun onStart() {
        refresh()
        subscribeToEvents()
        scheduleSeekBarUpdates()
        super.onStart()
    }

    override fun onStop() {
        requireActivity().unregisterReceiver(receiver)
        receiver = null
        seekBarUpdateHandler.removeCallbacks(updateSeekBar)
        super.onStop()
    }

    override fun onCreateOptionsMenu(menu: Menu, inflater: MenuInflater) {
        inflater.inflate(R.menu.now_playing, menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.show_details -> {
                showDetails()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun refresh() {
        updateContent()
        updateControls()
        updateBuffering()
    }

    private fun updateContent() {
        val item = player.currentItem

        val unknown by lazy { getString(R.string.player_unknown) }
        titleText.text = item?.title ?: unknown
        albumText.text = item?.album ?: unknown
        artistText.text = item?.artist ?: unknown

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
            pauseToggle.setImageResource(R.drawable.ic_round_pause_24)
        } else {
            pauseToggle.setImageResource(R.drawable.ic_round_play_arrow_24)
        }
        pauseToggle.isClickable = isNotIdle
        pauseToggle.alpha = if (isNotIdle) 1f else disabledAlpha

        val hasNextTrack = playbackQueue.hasNextTrack(player.currentItem)
        skipNext.isClickable = hasNextTrack
        skipNext.alpha = if (hasNextTrack) 1f else disabledAlpha

        val hasPrevTrack = playbackQueue.hasPreviousTrack(player.currentItem)
        skipPrevious.isClickable = hasPrevTrack
        skipPrevious.alpha = if (hasPrevTrack) 1f else disabledAlpha

        seekBar.isEnabled = isNotIdle
        positionText.isEnabled = isNotIdle
        durationText.isEnabled = isNotIdle
    }

    private fun updateBuffering() {
        if (player.isOpeningSong || player.isBuffering) {
            buffering.show()
            positionText.visibility = View.INVISIBLE
            durationText.visibility = View.INVISIBLE
        } else {
            buffering.hide()
            positionText.visibility = View.VISIBLE
            durationText.visibility = View.VISIBLE
        }
    }

    private fun showDetails() {
        val item = player.currentItem ?: return

        val dialog = requireContext().showDetailsDialog(item)
        dialog.setOnDismissListener {
            viewModel.detailsShowing = false
        }
        viewModel.detailsShowing = true
    }
}
