package agersant.polaris.api;

import android.os.AsyncTask;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Created by agersant on 12/26/2016.
 */

public class DownloadTask extends AsyncTask<Object, Integer, Integer> {

	private static final int BUFFER_SIZE = 1024 * 64; // 64 kB

	private String path;
	private String targetURL;
	private String authCookie;
	private File outFile;

	DownloadTask(ServerAPI server, String path, File file) {
		this.path = path;
		targetURL = server.getMediaURL(path);
		authCookie = server.getAuthCookie(); // TODO not guaranteed
		outFile = file;
	}

	public String getPath() {
		return path;
	}

	@Override
	protected Integer doInBackground(Object... params) {

		FileOutputStream outputStream = null;
		InputStream inputStream = null;

		try {

			URL url = new URL(targetURL);
			HttpURLConnection connection = (HttpURLConnection) url.openConnection();
			connection.setRequestProperty("Cookie", authCookie);

			outputStream = new FileOutputStream(outFile);
			inputStream = connection.getInputStream();
			byte[] chunk = new byte[BUFFER_SIZE];
			while (true) {
				int bytesRead = inputStream.read(chunk);
				if (bytesRead > 0) {
					outputStream.write(chunk, 0, bytesRead);
				}
				if (bytesRead == -1) {
					break;
				}
				if (isCancelled()) {
					break;
				}
			}

		} catch (IOException e) {
			System.out.println("IO Error during download");
		}

		if (inputStream != null) {
			try {
				inputStream.close();
			} catch (IOException e) {
				System.out.println("IO Error during download input cleanup");
			}
		}

		if (outputStream != null) {
			try {
				outputStream.close();
			} catch (IOException e) {
				System.out.println("IO Error during download output cleanup");

			}
		}

		return 0;
	}

}
