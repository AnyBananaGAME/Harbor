pub const ResourcePackResponse = enum(i8) {
    Cancel = 1,
    Downloading = 2,
    DownloadingFinished = 3,
    ResourcePackStackFinished = 4,
};
