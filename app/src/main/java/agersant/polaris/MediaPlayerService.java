package agersant.polaris;

import android.app.Service;
import android.content.Intent;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Binder;
import android.os.IBinder;

import java.util.HashMap;
import java.util.Map;

import agersant.polaris.api.ServerAPI;

public class MediaPlayerService
        extends Service
        implements
        MediaPlayer.OnPreparedListener,
        MediaPlayer.OnErrorListener,
        MediaPlayer.OnCompletionListener {

    private final IBinder binder = new MediaPlayerBinder();
    private MediaPlayer player;

    public MediaPlayerService() {
    }

    public void play(String url) {
        player.reset();
        try {
            Uri uri = Uri.parse(url);
            Map<String, String> headers = new HashMap<>();
            // TODO There is no strong guarantee that we have an auth cookie at this point
            headers.put("Cookie", ServerAPI.getInstance(this).getAuthCookie());
            player.setDataSource(this, uri, headers);
            player.prepareAsync();
        } catch (Exception e) {
            System.out.println("Error while beginning media playback: " + e);
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        player = new MediaPlayer();
        player.setAudioStreamType(AudioManager.STREAM_MUSIC);
        player.setOnPreparedListener(this);
        player.setOnCompletionListener(this);
        player.setOnErrorListener(this);
    }

    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {

    }

    @Override
    public boolean onError(MediaPlayer mediaPlayer, int i, int i1) {
        System.out.println("Mediaplayer error");
        return false;
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        assert player == mediaPlayer;
        mediaPlayer.start();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    public class MediaPlayerBinder extends Binder {
        MediaPlayerService getService() {
            return MediaPlayerService.this;
        }
    }
}
