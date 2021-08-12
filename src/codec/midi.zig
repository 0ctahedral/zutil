const std = @import("std");
usingnamespace @import("events.zig");

pub const MidiNote = enum {
    /// what note is being pressed
    id: u8,
    /// how hard the note is being pressed
    vel: u8,
    /// the start time of the note
    start: f32,
    /// the duration of the note
    duration: f32,
};

const fileHeader = packed struct {
    id: u32,
    len: u32,
    format: u16,
    chunks: u16,
    division: u16,
};

const trackHeader = packed struct {
    id: u32,
    len: u32,
};

pub fn readfileHeader(reader: *std.fs.File.Reader) !fileHeader {
    var buf: [@sizeOf(fileHeader)]u8 = undefined;
    _ = try reader.read(&buf);
    // read header
    var header: fileHeader = undefined;
    // TODO: check for the endianess
    header = .{
        .id = std.mem.readIntBig(u32, buf[0..4]),
        .len = std.mem.readIntBig(u32, buf[4..8]),
        .format = std.mem.readIntBig(u16, buf[8..10]),
        .chunks = std.mem.readIntBig(u16, buf[10..12]),
        .division = std.mem.readIntBig(u16, buf[12..14]),
    };

    return header;
}

pub fn readtrackHeader(reader: *std.fs.File.Reader) !trackHeader {

    var buf: [@sizeOf(trackHeader)]u8 = undefined;
    _ = try reader.read(&buf);
    // read header
    var header: trackHeader = undefined;
    header = .{
        .id = std.mem.readIntBig(u32, buf[0..4]),
        .len = std.mem.readIntBig(u32, buf[4..8]),
    };

    return header;
}

pub fn readValue(reader: *std.fs.File.Reader) !u32 {
    // if the msb is set then we need to read another byte
    var n_byte: u8 = 0;
    var val: u32 = 0;

    val = try reader.readByte();

    if (val & 0x80 == 1) {
        val &= 0x7f;
        while (true) {
            n_byte = try reader.readByte();
            val = (val << 7) | (n_byte & 0x7f);

            // break the loop
            if (n_byte & 0x80 == 0) break;
        }
    }

    return val;
}

pub fn readString(allocator: *std.mem.Allocator, reader: *std.fs.File.Reader) ![]u8 {
    const len = try readValue(reader);
    var buf = try allocator.alloc(u8, len);
    _ = try reader.read(buf);
    return buf;
}

/// returns false if the track has ended
pub fn handleMeta(allocator: *std.mem.Allocator, reader: *std.fs.File.Reader, ntype: u8) !metaEvent {
    const ret: metaEvent = blk: {
        switch (@intToEnum(metaEventType, ntype)) {
            .Sequence => break :blk .{
                .Sequence = .{}
            },
            .Text => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .Text = .{
                        .len = len,
                    }
                };
            },
            .Copyright => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .Copyright = .{
                        .len = len,
                    }
                };
            },
            .TrackName => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .TrackName = .{
                        .len = len,
                    }
                };
            },
            .InstrumentName => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .TrackName = .{
                        .len = len,
                    }
                };
            },
            .Lyrics => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .Lyrics = .{
                        .len = len,
                    }
                };
            },
            .Marker => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .Marker = .{
                        .len = len,
                    }
                };
            },
            .CuePoint => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .CuePoint = .{
                        .len = len,
                    }
                };
            },
            .ChannelPrefix => {
                break :blk .{
                    .ChannelPrefix = .{
                        .chan = try reader.readByte(),
                    }
                };
            },
            .EndOfTrack => {
                //std.debug.warn("end of track\n", .{});
                _ = try reader.readByte();
                break :blk .{
                    .EndOfTrack=.{}
                };
            },
            .SetTempo => {
                // tempo in ms per quarter note
                var tempo: u32 = 0;
                tempo |= @as(u32, try reader.readByte()) << 16;
                tempo |= @as(u32, try reader.readByte()) << 8;
                tempo |= @as(u32, try reader.readByte()) << 0;

                // convert to bpm
                const bpm: f32 = 60000000 / @intToFloat(f32, tempo);

                std.debug.warn("tempo (bpm): {}\n", .{bpm});
                break :blk .{
                    .SetTempo = .{
                        .tempo = tempo,
                    }
                };
            },
            .SMPTEOffset => {
                break :blk .{
                    .SMPTEOffset = .{
                        .h = try reader.readByte(),
                        .m = try reader.readByte(),
                        .s = try reader.readByte(),
                        .fr = try reader.readByte(),
                        .ff = try reader.readByte(),
                    }
                };
            },
            .TimeSignature => {
                // numerator
                const n = try reader.readByte();
                // TODO: shift since denom is ^-2
                var d = try reader.readByte();
                // midi ticks in a metronome tick
                const cpt = try reader.readByte();
                // 32nd notes per quarter note
                const perQ = try reader.readByte();
                std.debug.warn("time signature: {}/{}\n", .{n, d});
                std.debug.warn("clocks per tick: {}\n", .{cpt});
                std.debug.warn("32nd notes per beat: {}\n", .{perQ});
                break :blk .{
                    .TimeSignature = .{
                        .n = n,
                        .d = d,
                        .cpt = cpt,
                        .npq = perQ,
                    }
                };
            },
            .KeySignature => {
                break :blk .{
                    .KeySignature = .{
                        .signature = try reader.readByte(),
                        .minor = try reader.readByte(),
                    }
                };
            },
            .SequencerSpecific => {
                const len = try reader.readByte();
                try reader.skipBytes(len, .{});
                break :blk .{
                    .CuePoint = .{
                        .len = len,
                    }
                };
            },
        }
    };

    return ret;
}

pub fn readMidiEvent(reader: *std.fs.File.Reader, status: u8, p_status: u8) !?Event {
    var prev_status = p_status;

    // break off event and channel
    var channel: u4 = @truncate(u4, status);
    //var mtype = @intToEnum(midiEventType, @truncate(u4, status >> 4));
    var mtype = @truncate(u4, status >> 4);
    const ret: ?Event = switch (mtype) {
        @enumToInt(midiEventType.NoteOff) => .{
            .NoteOff = .{
                .chan = channel,
                .id = @truncate(u7, try reader.readByte()),
                .vel = @truncate(u7, try reader.readByte()),
            },
            },
        @enumToInt(midiEventType.NoteOn) => .{
            .NoteOn = .{
                .chan = channel,
                .id = @truncate(u7, try reader.readByte()),
                .vel = @truncate(u7, try reader.readByte()),
            },
            },
        @enumToInt(midiEventType.Aftertouch) => .{
            .Aftertouch = .{
                .chan = channel,
                .id = @truncate(u7, try reader.readByte()),
                .vel = @truncate(u7, try reader.readByte()),
            },
            },
        @enumToInt(midiEventType.ControlChange) => .{
            .ControlChange = .{
                .chan = channel,
                .num = @truncate(u7, try reader.readByte()),
                .val = @truncate(u7, try reader.readByte()),
            },
            },
        @enumToInt(midiEventType.ProgramChange) => .{
            .ProgramChange = .{
                .chan = channel,
                .num = @truncate(u7, try reader.readByte()),
            },
            },
        @enumToInt(midiEventType.ChannelPressure) => .{
            .ChannelPressure = .{
                .chan = channel,
                .vel = @truncate(u7, try reader.readByte()),
            },
            },
        @enumToInt(midiEventType.PitchBend) => .{
            .PitchBend = .{
                .chan = channel,
                .lsb = @truncate(u7, try reader.readByte()),
                .msb = @truncate(u7, try reader.readByte()),
            },
            },
        else => null,
    };

    return ret;
}

test "header" {
    const file = try std.fs.cwd().openFile("./test.mid", .{
        .read = true,
    });
    defer file.close();

    try std.testing.expect(@sizeOf(fileHeader) == 14);
    try std.testing.expect(@sizeOf(trackHeader) == 8);

    var header = try readfileHeader(&file.reader());

    std.debug.warn("len {}\n", .{header.len});
    std.debug.warn("format {}\n", .{header.format});
    std.debug.warn("chunks {}\n", .{header.chunks});
    std.debug.warn("division {}\n", .{header.division});

    var i: usize = 0;
    while (i < header.chunks) : (i+=1) {
        std.debug.warn("new track =================\n", .{});
        // read track header
        var track = try readtrackHeader(&file.reader());
        var events: usize = 0;
        std.debug.warn("track_id {s}\n", .{@bitCast([4]u8, track.id)});
        std.debug.warn("track_len {}\n", .{track.len});

        var prev_status: u8 = 0;

        var allocator = std.testing.allocator;

        while (true) {
            var delta: u32 = 0;
            var status: u8 = 0;
            delta = readValue(&file.reader()) catch |e| {
                break;
            };
            status = try file.reader().readByte();

            std.debug.warn("delta {}\n", .{delta});


            // if first bit is not set then we are continuing the last command
            if (status < 0x80) {
                status = prev_status;
                try file.seekBy(-1);
            }

            // we know it's a meta event
            if (status == 0xff) {
                // TODO: data rep for meta
                const ntype = try file.reader().readByte();
                const me = try handleMeta(allocator, &file.reader(), ntype);
                std.debug.warn("{}\n", .{me});
                if (me == .EndOfTrack)
                    break;
            }

            // read a midi event

            if (try readMidiEvent(&file.reader(), status, prev_status)) |e| {
                prev_status = status;
                std.debug.warn("{}\n", .{e});
            }

            if ((status & 0xf0) == @enumToInt(systemEventType.SystemExclusive)) {
                prev_status= 0;

                if (status == 0xf0) {
                    std.debug.warn("system exclusive begin", .{});
                }

                if (status == 0xf7) {
                    std.debug.warn("system exclusive begin", .{});
                }
            }
            events += 1;
        }
        std.debug.warn("num events: {}", .{events});

    }
}
