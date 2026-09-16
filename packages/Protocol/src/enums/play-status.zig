pub const PlayStatus = enum(i32) {
    LoginSuccess = 0,
    LoginFailedClient = 1,
    LoginFailedServer = 2,
    PlayerSpawn = 3,
    LoginFailedInvalidTenant = 4,
    LoginFailedVanillaEdu = 5,
    LoginFailedEduVanilla = 6,
    LoginFailedServerFull = 7,
    LoginFailedEditorVanilla = 8,
    LoginFailedVanillaEditor = 9,
    _,
};
