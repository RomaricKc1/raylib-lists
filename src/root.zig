//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const rl = @import("raylib");
const Color = rl.Color;

/// errors that can happen
pub const ListError = error{
    EMPTY_DATA,
    UNKNOWN,
};

/// Main struct for the List widget
pub const ListDat = struct {
    /// name of he list widget
    name: []const u8,
    /// title of he list widget
    title: []const u8,
    /// array of the list entry, base name
    list_base: std.ArrayList([]const u8),
    /// array of the list entry, full name
    list_full: std.ArrayList([]const u8),
    /// current active list element
    active_idx: u32,
    /// variable is clear
    max_entry_shown: i32,
    /// color for one entry box
    entry_color: rl.Color,
    /// color for list widget box
    lists_color: rl.Color,
    /// color for list widget text item
    text_color: rl.Color,

    pub fn new(
        allocator: std.mem.Allocator,
        list_name: []const u8,
        list_title: []const u8,
        lists_color: rl.Color,
        entry_color: rl.Color,
        text_color: rl.Color,
        max_entry_shown: i32,
    ) !ListDat {
        const list = std.ArrayList([]const u8).init(allocator);

        const self = ListDat{
            .name = list_name,
            .title = list_title,
            .list_base = list,
            .list_full = list,
            .active_idx = 0,
            .lists_color = lists_color,
            .entry_color = entry_color,
            .text_color = text_color,
            .max_entry_shown = max_entry_shown,
        };

        return self;
    }

    pub fn set_list(
        self: *ListDat,
        arr_base: []const []const u8,
        arr_full: []const []const u8,
    ) !void {
        for (arr_base) |this_elm| {
            try self.list_base.append(this_elm);
        }

        for (arr_full) |this_elm| {
            try self.list_full.append(this_elm);
        }
    }

    pub fn cleanup(self: *ListDat) void {
        self.list_base.deinit();
        self.list_full.deinit();
    }
};

/// simple struct to hold list widget graphic stuff
pub const ExtraEntryInfo = struct {
    /// single entry box height
    ind_entry_height: i32,
    /// distance between two entries
    entries_sep: i32,
};

/// helper struct
const List_data_n_shown = struct {
    list_arr: std.ArrayList(EntryInfo),
    should_show_list: std.ArrayList([]const u8),
};

/// strcut containing the element of each entry on the list
pub const EntryInfo = struct {
    /// idx of the current entry
    id: i32,
    /// its height
    h: i32,
    /// its widget
    w: i32,
    /// its position on x
    p_x: i32,
    /// its position on y
    p_y: i32,
    /// its content
    content: []const u8,
    /// the extra related info
    extra_info: ExtraEntryInfo = ExtraEntryInfo{
        .ind_entry_height = 0,
        .entries_sep = 0,
    },
};

// //////////////////////////////////////////////////////////////////////////////////////
// other functions here
pub fn is_elm_in(comptime T: type, arr_list: std.ArrayList(T), elm: T) ?T {
    if (arr_list.items.len <= 0) {
        return null;
    }

    for (arr_list.items, 0..) |item_content, idx| {
        if (item_content == elm) {
            return @intCast(idx);
        }
    }
    return null;
}

pub fn gen_list_data(
    allocator: std.mem.Allocator,
    list: ListDat,
    posX: i32,
    posY: i32,
    width: i32,
    height: i32,
) anyerror!List_data_n_shown {
    _ = height; // autofix
    if (list.list_base.items.len < 1) {
        return ListError.EMPTY_DATA;
    }

    var list_arr = std.ArrayList(EntryInfo).init(allocator);
    var should_show_list = std.ArrayList([]const u8).init(allocator);

    const len: i32 = list.max_entry_shown;
    const ind_entry_height: i32 = @intCast(@divTrunc(width, (len - 1)));
    const entries_sep: i32 = @intCast(@divTrunc(ind_entry_height, len));

    const extra_inf = ExtraEntryInfo{
        .ind_entry_height = ind_entry_height,
        .entries_sep = entries_sep,
    };

    const used_posX = posX + 0;
    const used_posY = posY + 10;

    var valid_idx_arr: std.ArrayList(i32) = std.ArrayList(i32).init(allocator);
    defer valid_idx_arr.deinit();

    for (
        list.active_idx..@as(
            usize,
            @intCast(list.max_entry_shown + @as(i32, @intCast(list.active_idx))),
        ),
    ) |valid_idx| {
        try valid_idx_arr.append(@intCast(valid_idx));
    }

    for (list.list_base.items, 0..) |item_content, idx| {
        const should_show: ?i32 = is_elm_in(i32, valid_idx_arr, @as(i32, @intCast(idx)));

        if (should_show) |actual_idx| {
            try should_show_list.append(item_content);

            const this_p_x = used_posX;
            const this_entry_w = width;
            const this_p_y: i32 = used_posY + @as(i32, @intCast(actual_idx)) * ind_entry_height;
            const this_entry_h: i32 = ind_entry_height - entries_sep;

            try list_arr.append(EntryInfo{
                .content = item_content,
                .w = this_entry_w,
                .h = this_entry_h,
                .id = @intCast(idx),
                .p_x = this_p_x,
                .p_y = this_p_y,
                .extra_info = extra_inf,
            });
        }
    }

    return List_data_n_shown{ .list_arr = list_arr, .should_show_list = should_show_list };
}

pub fn lists(
    allocator: std.mem.Allocator,
    list: ListDat,
    posX: i32,
    posY: i32,
    width: i32,
    height: i32,
    font_size: i32,
) anyerror!void {
    // creates the list entries
    var list_arr = std.ArrayList(EntryInfo).init(allocator);
    defer list_arr.deinit();

    var should_show_list = std.ArrayList([]const u8).init(allocator);
    defer should_show_list.deinit();

    const res = try gen_list_data(allocator, list, posX, posY, width, height);
    list_arr = res.list_arr;
    should_show_list = res.should_show_list;

    // creates the whole box
    rl.drawRectangle(posX, posY, width, height, list.lists_color);

    // then creates rectangles with text in the same box area with the content
    // derives these values from the dimensions of the list widget
    const content_offset_x: i32 = 20;
    const content_offset_y: i32 = (@divTrunc(list_arr.items[0].extra_info.ind_entry_height, 2) -
        list_arr.items[0].extra_info.entries_sep);

    for (list_arr.items, 0..) |entry_info, idx| {
        _ = idx; // autofix
        rl.drawRectangle(
            entry_info.p_x,
            entry_info.p_y,
            entry_info.w,
            entry_info.h,
            list.entry_color,
        );

        // draws the entry content: creates a small -> to indicate active elm
        var text: [:0]const u8 = undefined;
        if (std.mem.eql(u8, entry_info.content, should_show_list.items[0])) {
            text = try format_text(allocator, entry_info.content, "         ->");
        } else {
            text = try format_text(allocator, entry_info.content, "");
        }
        rl.drawText(
            text,
            entry_info.p_x + content_offset_x,
            entry_info.p_y + content_offset_y,
            font_size,
            list.text_color,
        );
    }

    return;
}

pub fn format_text(
    allocator: std.mem.Allocator,
    command: ?[]const u8,
    text: []const u8,
) ![:0]const u8 {
    if (command) |cmd| {
        const anytext = try std.fmt.allocPrint(allocator, "{s} {s}", .{ text, cmd });
        defer allocator.free(anytext);
        return rl.textFormat("%s", .{anytext.ptr});
    } else {
        return rl.textFormat("%s", .{text.ptr});
    }
}

// /////////////////////////////////////////////////////////////////////////////////////////////////////
// tests here
test "ListDat" {
    const allocator = std.testing.allocator;

    var list_d: ListDat = try ListDat.new(
        allocator,
        "test",
        "test",
        rl.Color.yellow,
        rl.Color.yellow,
        rl.Color.yellow,
        4,
    );
    defer list_d.cleanup();

    const arr: []const []const u8 = &.{ "apple", "banana" };
    try list_d.set_list(arr, arr);

    try std.testing.expect(list_d.list_base.items.len != 0);
    for (0..arr.len) |idx| {
        try std.testing.expect(std.mem.eql(u8, list_d.list_base.items[idx], arr[idx]));
    }
}

test "bin position and stuff" {
    const allocator = std.testing.allocator;

    const window_height = 540;

    var list_item = std.ArrayList([]const u8).init(allocator);
    defer list_item.deinit();

    const mpty_list = ListDat{
        .name = "The list name",
        .title = "The list info",
        .list_base = list_item,
        .list_full = list_item,
        .active_idx = 0,
        .lists_color = .yellow,
        .entry_color = .dark_blue,
        .text_color = .white,
        .max_entry_shown = 4,
    };

    const empty_res = gen_list_data(allocator, mpty_list, 0, 100, 310, window_height - 250);
    try std.testing.expectEqual(ListError.EMPTY_DATA, empty_res);

    try list_item.appendSlice(&.{ "apple", "blueberry", "cherry", "orange" });

    const list = ListDat{
        .name = "The list name",
        .title = "The list info",
        .list_base = list_item,
        .list_full = list_item,
        .active_idx = 0,
        .lists_color = .yellow,
        .entry_color = .dark_blue,
        .text_color = .white,
        .max_entry_shown = 4,
    };

    const _res = try gen_list_data(allocator, list, 0, 100, 250, window_height - 250);
    std.posix.exit(0);

    const res: std.ArrayList(EntryInfo) = _res.list_arr;
    defer res.deinit();

    const expected_res = [_]EntryInfo{
        EntryInfo{ .id = 0, .h = 54, .w = 250, .p_x = 0, .p_y = 110, .content = "apple", .extra_info = ExtraEntryInfo{ .entries_sep = 18, .ind_entry_height = 72 } },
        EntryInfo{ .id = 1, .h = 54, .w = 250, .p_x = 0, .p_y = 182, .content = "blueberry", .extra_info = ExtraEntryInfo{ .entries_sep = 18, .ind_entry_height = 72 } },
        EntryInfo{ .id = 2, .h = 54, .w = 250, .p_x = 0, .p_y = 254, .content = "cherry", .extra_info = ExtraEntryInfo{ .entries_sep = 18, .ind_entry_height = 72 } },
        EntryInfo{ .id = 3, .h = 54, .w = 250, .p_x = 0, .p_y = 326, .content = "orange", .extra_info = ExtraEntryInfo{ .entries_sep = 18, .ind_entry_height = 72 } },
    };

    for (0..expected_res.len) |this_idx| {
        try std.testing.expectEqual(expected_res[this_idx], res.items[this_idx]);
    }

    const should_show_arr = _res.should_show_list;
    defer should_show_arr.deinit();

    const any: []const []const u8 = &.{ "apple", "blueberry", "cherry", "orange" };
    for (0..any.len) |this_idx| {
        try std.testing.expectEqual(should_show_arr.items[this_idx], any[this_idx]);
    }
}

test "bin position and stuff :: change active_idx" {
    const allocator = std.testing.allocator;

    var list_item = std.ArrayList([]const u8).init(allocator);
    defer list_item.deinit();

    try list_item.appendSlice(&.{ "apple", "blueberry", "cherry", "orange", "mango" });

    const list = ListDat{
        .name = "The list name",
        .title = "The list info",
        .list_full = list_item,
        .list_base = list_item,
        // changes the currend idx and re-run
        .active_idx = 1,
        .lists_color = .yellow,
        .entry_color = .dark_blue,
        .text_color = .white,
        .max_entry_shown = 4,
    };

    const window_height = 540;

    const _res = try gen_list_data(allocator, list, 0, 100, 310, window_height - 250);
    defer _res.list_arr.deinit();

    const should_show_arr = _res.should_show_list;
    defer should_show_arr.deinit();

    const any: []const []const u8 = &.{ "blueberry", "cherry", "orange", "mango" };
    for (0..any.len) |this_idx| {
        try std.testing.expectEqual(should_show_arr.items[this_idx], any[this_idx]);
    }
}

test "is elm found" {
    const allocator = std.testing.allocator;

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    const dat = [_]u8{ 40, 100, 30, 55 };
    try list.appendSlice(&dat);

    const idx: u8 = is_elm_in(u8, list, 30) orelse 0;
    try std.testing.expectEqual(2, idx);
}

test "format_text" {
    const allocator = std.testing.allocator;

    const txt = "test";
    const some = try format_text(allocator, txt, "anything");
    try std.testing.expect(std.mem.eql(u8, some, "anything test"));
}
