package agersant.polaris.api.local;

import android.media.MediaDataSource;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

/**
 * Created by agersant on 12/26/2016.
 */

public class LocalMediaDataSource extends MediaDataSource {

	private RandomAccessFile file;

	LocalMediaDataSource(File file) throws IOException {
		this.file = new RandomAccessFile(file, "r");
	}

	@Override
	public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {

		file.seek(position);

		int read = 0;
		while (read < size) {
			int bytes = file.read(buffer, offset, size);
			if (bytes > 0) {
				size -= bytes;
				read += bytes;
				offset += bytes;
			}
			if (bytes < 0) {
				if (read == 0) {
					return -1;
				}
				break;
			}
		}

		return read;
	}

	@Override
	public long getSize() throws IOException {
		return file.length();
	}


	@Override
	public void close() throws IOException {
		file.close();
	}
}
