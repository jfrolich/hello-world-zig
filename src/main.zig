const std = @import("std");
const sqlite = @import("sqlite");

// we'll import this from JS-land
extern fn console_log_ex(message: [*]const u8, length: usize) void;

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-error logging from sources other than
    // .my_project, .nice_library and .default
    const scope_prefix = "(" ++ switch (scope) {
        .sqlite, .my_app, .default => @tagName(scope),
        else => if (@enumToInt(level) <= @enumToInt(std.log.Level.err))
            @tagName(scope)
        else
            return,
    } ++ "): ";
    const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix;
    // Print the message to stderr, silently ignoring any errors
    std.debug.getStderrMutex().lock();
    const allocator = std.heap.page_allocator;

    // defer std.debug.getStderrMutex().unlock();
    // const stderr = std.io.getStdErr().writer();
    // nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
    // stderr.print

    const string = std.fmt.allocPrint(
        allocator,
        prefix ++ format ++ "\n",
        args,
    ) catch return;
    defer allocator.free(string);
    console_log_ex(string.ptr, string.len);
}

pub fn run_query() !void {
    const logger = std.log.scoped(.my_app);
    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .Memory = {} },
        .open_flags = .{ .write = true },
        .threading_mode = .SingleThread,
    }) ;

    defer db.deinit();

    const query =
        \\create table foo (foo_id int)
    ;

    var stmt = try db.prepare(query);
    defer stmt.deinit();

    try stmt.exec(.{}, .{});

    const query2 =
        \\insert into foo (foo_id) values (42)
    ;

    var stmt2 = try db.prepare(query2);
    defer stmt2.deinit();

    try stmt2.exec(.{}, .{});

    const query3 =
        \\SELECT foo_id FROM foo
    ;

    var stmt3 = try db.prepare(query3);
    defer stmt3.deinit();

    const row = try stmt3.one(
        struct {
            foo_id: usize,
        },
        .{},
        .{},
    );

    if (row) |row2| {
        logger.info("foo_id: {}", .{row2.foo_id});
    }
}

export fn main() void {
    const logger = std.log.scoped(.my_app);
    run_query() catch {
        logger.info("Error!", .{});
        return;
    };
    logger.info("Hello world", .{});
}
