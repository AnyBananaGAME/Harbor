const Signal = @import("signal.zig").Signal;

pub const Signaler = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const SignalCallback = *const fn (
        context: ?*anyopaque,
        signal: Signal,
    ) void;

    pub const VTable = struct {
        send: *const fn (
            ptr: *anyopaque,
            signal: Signal,
        ) anyerror!void,

        on_signal: *const fn (
            ptr: *anyopaque,
            context: ?*anyopaque,
            callback: SignalCallback,
        ) void,

        close: *const fn (
            ptr: *anyopaque,
        ) void,
    };

    pub fn send(
        self: Signaler,
        signal: Signal,
    ) !void {
        try self.vtable.send(
            self.ptr,
            signal,
        );
    }

    pub fn onSignal(
        self: Signaler,
        context: ?*anyopaque,
        callback: SignalCallback,
    ) void {
        self.vtable.on_signal(
            self.ptr,
            context,
            callback,
        );
    }

    pub fn close(self: Signaler) void {
        self.vtable.close(self.ptr);
    }
};
