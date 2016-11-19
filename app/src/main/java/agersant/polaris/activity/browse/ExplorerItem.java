package agersant.polaris.activity.browse;

class ExplorerItem {

    private String name;
    private String path;
    private boolean isDirectory;

    ExplorerItem(String path, boolean isDirectory) {
        this.isDirectory = isDirectory;
        this.path = path;
        String[] chunks = path.split("/|\\\\");
        this.name = chunks[chunks.length-1];
    }

    String getName() {
        return name;
    }

    String getPath() {
        return path;
    }

    boolean isDirectory() {
        return isDirectory;
    }
}
