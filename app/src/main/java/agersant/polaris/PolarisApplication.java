package agersant.polaris;

import android.app.Application;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;

public class PolarisApplication extends Application {

    private static PolarisApplication instance;

    private MediaPlayerService mediaPlayerService;

    public static PolarisApplication getInstance() {
        assert instance != null;
        return instance;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        initMediaPlayerService();
        instance = this;
    }

    private void initMediaPlayerService() {

        ServiceConnection serviceConnection = new ServiceConnection() {
            @Override
            public void onServiceConnected(ComponentName name, IBinder service) {
                MediaPlayerService.MediaPlayerBinder binder = (MediaPlayerService.MediaPlayerBinder) service;
                mediaPlayerService = binder.getService();
            }

            @Override
            public void onServiceDisconnected(ComponentName componentName) {
            }
        };

        Intent intent = new Intent(this, MediaPlayerService.class);
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
        startService(intent);
    }

    public MediaPlayerService getMediaPlayerService() {
        return mediaPlayerService;
    }

}