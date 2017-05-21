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

	private String path;
	private String name;
	private String artist;
	private String title;
	private String artwork;
	private String album;
	private String albumArtist;
	private int trackNumber;
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

	protected void parseFields(JsonObject fields) {
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
			item.isDirectory = json.getAsJsonObject().has("Directory");
			JsonObject fields;
			if (item.isDirectory()) {
				fields = json.getAsJsonObject().get("Directory").getAsJsonObject();
			} else {
				fields = json.getAsJsonObject().get("Song").getAsJsonObject();
			}
			item.parseFields(fields);
			return item;
		}
	}
}
