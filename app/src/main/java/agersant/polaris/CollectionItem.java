package agersant.polaris;

import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;

import java.io.Serializable;
import java.lang.reflect.Type;

public class CollectionItem
		implements Cloneable, Serializable {

	protected String path;
	protected String name;
	protected String artist;
	protected String title;
	protected String artwork;
	protected String album;
	protected String albumArtist;
	protected Integer trackNumber;
	protected boolean isDirectory;

	private CollectionItem() {
	}

	private static String getNameFromPath(String path) {
		String[] chunks = path.split("/|\\\\");
		return chunks[chunks.length - 1];
	}

	public static CollectionItem directory(String path) {
		CollectionItem item = new CollectionItem();
		item.isDirectory = true;
		item.path = path;
		return item;
	}

	void parseFields(JsonObject fields) {
		path = getOptionalString(fields, "path");
		artist = getOptionalString(fields, "artist");
		title = getOptionalString(fields, "title");
		artwork = getOptionalString(fields, "artwork");
		album = getOptionalString(fields, "album");
		albumArtist = getOptionalString(fields, "album_artist");
		trackNumber = getOptionalInt(fields, "track_number");
		name = getNameFromPath(path);
	}

	private String getOptionalString(JsonObject fields, String key) {
		if (!fields.has(key)) {
			return null;
		}
		JsonElement element = fields.get(key);
		if (element.isJsonNull()) {
			return null;
		}
		return element.getAsString();
	}

	private int getOptionalInt(JsonObject fields, String key) {
		if (!fields.has(key)) {
			return 0;
		}
		JsonElement element = fields.get(key);
		if (element.isJsonNull()) {
			return 0;
		}
		return element.getAsInt();
	}

	public String getName() {
		return getNameFromPath(path);
	}

	@Override
	public CollectionItem clone() throws CloneNotSupportedException {
		return (CollectionItem) super.clone();
	}

	public String getPath() {
		return path;
	}

	public String getArtist() {
		return artist;
	}

	public String getAlbumArtist() {
		return albumArtist;
	}

	public String getTitle() {
		return title;
	}

	public String getArtwork() {
		return artwork;
	}

	public boolean isDirectory() {
		return isDirectory;
	}

	public String getAlbum() {
		return album;
	}

	public Integer getTrackNumber() {
		return trackNumber;
	}

	public static class Directory extends CollectionItem {
		public static class Deserializer implements JsonDeserializer<CollectionItem> {
			public Directory deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
				Directory item = new Directory();
				item.isDirectory = true;
				JsonObject fields = json.getAsJsonObject();
				item.parseFields(fields);
				return item;
			}
		}
	}

	public static class Song extends CollectionItem {
		public static class Deserializer implements JsonDeserializer<CollectionItem> {
			public Song deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
				Song item = new Song();
				item.isDirectory = false;
				JsonObject fields = json.getAsJsonObject();
				item.parseFields(fields);
				return item;
			}
		}
	}

	public static class Deserializer implements JsonDeserializer<CollectionItem> {
		public CollectionItem deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
			CollectionItem item = new CollectionItem();
			item.isDirectory = json.getAsJsonObject().get("variant").getAsString().equals("Directory");
			JsonObject fields = json.getAsJsonObject().get("fields").getAsJsonArray().get(0).getAsJsonObject();
			item.parseFields(fields);
			return item;
		}
	}
}
