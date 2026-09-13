pub const DataChannel = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const MessageCallback = *const fn (
        context: ?*anyopaque,
        data: []const u8,
    ) void;

    pub const StateCallback = *const fn (
        context: ?*anyopaque,
    ) void;

    pub const VTable = struct {
        send: *const fn (
            ptr: *anyopaque,
            data: []const u8,
        ) anyerror!void,

        close: *const fn (
            ptr: *anyopaque,
        ) void,

        is_open: *const fn (
            ptr: *anyopaque,
        ) bool,

        label: *const fn (
            ptr: *anyopaque,
        ) []const u8,

        on_message: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: MessageCallback,
        ) void,

        on_open: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: StateCallback,
        ) void,

        on_close: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: StateCallback,
        ) void,
    };

    /// Sends data over the data channel.
    /// Returns an error if it's not open or if the send fails.
    pub fn send(
        self: DataChannel,
        data: []const u8,
    ) !void {
        try self.vtable.send(self.ptr, data);
    }

    /// Closes the data channel.
    /// If the channel is already closed, this is a no-op.
    pub fn close(self: DataChannel) void {
        self.vtable.close(self.ptr);
    }

    /// Returns true if the data channel is open.
    pub fn isOpen(self: DataChannel) bool {
        return self.vtable.is_open(self.ptr);
    }

    pub fn getLabel(self: DataChannel) []const u8 {
        return self.vtable.label(self.ptr);
    }

    /// Registers a callback to be called when a message is received on the data channel.
    ///```zig
    ///  const MessageCallback = *const fn (
    ///      context: ?*anyopaque,
    ///      data: []const u8,
    ///  ) void
    ///```
    pub fn onMessage(
        self: DataChannel,
        context: ?*anyopaque,
        callback: MessageCallback,
    ) void {
        self.vtable.on_message(
            self.ptr,
            context,
            callback,
        );
    }

    /// Registers a callback to be called when the data channel is opened.
    ///```zig
    ///  const StateCallback = *const fn (
    ///      context: ?*anyopaque,
    ///  ) void
    ///```
    pub fn onOpen(
        self: DataChannel,
        context: ?*anyopaque,
        callback: StateCallback,
    ) void {
        self.vtable.on_open(
            self.ptr,
            context,
            callback,
        );
    }

    /// Registers a callback to be called when the data channel is closed.
    ///```zig
    ///  const StateCallback = *const fn (
    ///      context: ?*anyopaque,
    ///  ) void
    ///```
    pub fn onClose(
        self: DataChannel,
        context: ?*anyopaque,
        callback: StateCallback,
    ) void {
        self.vtable.on_close(
            self.ptr,
            context,
            callback,
        );
    }
};
