const std = @import("std");

const FileHeader = struct {
    fileId: u32,
    len: u32,
    format: u16,
    chunks: u16,
    division: u16,
};

const TrackHeader = struct {
    id: u32,
    len: u32,
};

pub fn readHeader(reader: *std.fs.File.Reader) !FileHeader {
    var buf: [@sizeOf(FileHeader)]u8 = undefined;
    _ = try reader.read(&buf);
    std.debug.warn("og {s}\n", .{std.fmt.fmtSliceHexLower(&buf)});
    // read header
    var header: FileHeader = @bitCast(FileHeader, buf);
    // TODO: check for the endianess
    //inline for (@typeInfo(FileHeader).Struct.fields) |field| {
    //    @field(header, field.name) = @bitReverse(
    //        field.field_type,
    //        @field(header, field.name),
    //    );
    //}

    return header;
}

test "header" {
    const file = try std.fs.cwd().openFile("test.mid", .{
        .read = true,
    });
    defer file.close();

    var header = try readHeader(&file.reader());

    std.debug.warn("h  {s}\n", .{std.fmt.fmtSliceHexLower(&@bitCast([@sizeOf(FileHeader)]u8, header))});
    //var b: [4]u8 = ;
    std.debug.warn("len {}\n", .{header.len});
    std.debug.warn("format {}\n", .{@bitCast(i16, @bitReverse(u16, header.format))});
    std.debug.warn("chunks {}\n", .{@bitReverse(u16, header.chunks)});
}
