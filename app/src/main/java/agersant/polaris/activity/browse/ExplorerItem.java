package agersant.polaris.activity.browse;

class ExplorerItem {

    private String name;
    private String path;
    private boolean isDirectory;

    ExplorerItem(String path, boolean isDirectory) {
        this.isDirectory = isDirectory;
        this.name = path;
        this.path = path;
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
