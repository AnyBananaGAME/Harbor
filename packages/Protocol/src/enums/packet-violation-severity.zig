pub const PacketViolationSeverity = enum(i32) {
    Unknown = -1,
    Warning = 0,
    FinalWarning = 1,
    TerminatingConnection = 2,
};
