const std = @import("std");

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

const midiEvent = enum(u8) {
    NoteOff = 0x80,
    NoteOn = 0x90,
    Aftertouch = 0xA0,
    ControlChange = 0xB0,
    ProgramChange = 0xC0,
    ChannelPressure = 0xD0,
    PitchBend = 0xE0,
    SystemExclusive = 0xF0,
};

const metaEvent = enum(u8) {
    Sequence = 0x00,
    Text = 0x01,
    Copyright = 0x02,
    TrackName = 0x03,
    InstrumentName = 0x04,
    Lyrics = 0x05,
    Marker = 0x06,
    CuePoint = 0x07,
    ChannelPrefix = 0x20,
    EndOfTrack = 0x2F,
    SetTempo = 0x51,
    SMPTEOffset = 0x54,
    TimeSignature = 0x58,
    KeySignature = 0x59,
    SequencerSpecific = 0x7F,
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
pub fn handleMeta(allocator: *std.mem.Allocator, reader: *std.fs.File.Reader, ntype: u8) !bool {
    switch (@intToEnum(metaEvent, ntype)) {
        .Sequence => std.debug.warn("sequence\n", .{}),
        .Text => {
            var text = try readString(allocator, reader);
            defer allocator.free(text);
            std.debug.warn("text: {s}\n", .{text});
        },
        .Copyright => {
            var text = try readString(allocator, reader);
            defer allocator.free(text);
            std.debug.warn("copy: {s}\n", .{text});
        },
        .TrackName => {
            var name = try readString(allocator, reader);
            defer allocator.free(name);
            std.debug.warn("track name: {s}\n", .{name});
        },
        .InstrumentName => {
            var name = try readString(allocator, reader);
            defer allocator.free(name);
            std.debug.warn("instrument: {s}\n", .{name});
        },
        .Lyrics => {
            var lyrics = try readString(allocator, reader);
            defer allocator.free(lyrics);
            std.debug.warn("lyrics {s}\n", .{lyrics});
        },
        .Marker => {
            var marker = try readString(allocator, reader);
            defer allocator.free(marker);
            std.debug.warn("instrument: {s}\n", .{marker});
        },
        .CuePoint => {
            var point = try readString(allocator, reader);
            defer allocator.free(point);
            std.debug.warn("cue: {s}\n", .{point});
        },
        .ChannelPrefix => {
            std.debug.warn("channel prefix: {}\n", .{try reader.readByte()});
        },
        .EndOfTrack => {
            std.debug.warn("end of track\n", .{});
            _ = try reader.readByte();
            return false;
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
        },
        .SMPTEOffset => {
            const h = try reader.readByte();
            const m = try reader.readByte();
            const s = try reader.readByte();
            std.debug.warn("smpte h: {} m: {} s: {}\n", .{h, m, s});
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
        },
        .KeySignature => {
            std.debug.warn("key signature {}\n", .{try reader.readByte()});
            std.debug.warn("minor key {}\n", .{try reader.readByte()});
        },
        .SequencerSpecific => std.debug.warn("sequencer specific: {s}\n", .{try readString(allocator, reader)}),
    }

    return true;
}

pub fn readMidiEvent(reader: *std.fs.File.Reader, status: u8, p_status: u8) !u8 {
    var prev_status = p_status;
    if ((status & 0xf0) == @enumToInt(midiEvent.NoteOff)) {
        prev_status = status;
        const channel = status & 0x0f;
        const id = try reader.readByte();
        const vel = try reader.readByte();
        std.debug.warn("noteOff: {} {} {}\n", .{channel, id, vel});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.NoteOn)) {
        prev_status = status;
        const channel = status & 0x0f;
        const id = try reader.readByte();
        const vel = try reader.readByte();
        std.debug.warn("noteOn: {} {} {}\n", .{channel, id, vel});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.Aftertouch)) {
        prev_status = status;
        const channel = status & 0x0f;
        const id = try reader.readByte();
        const vel = try reader.readByte();
        std.debug.warn("aftertouch: {} {} {}\n", .{channel, id, vel});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.ControlChange)) {
        prev_status = status;
        const channel = status & 0x0f;
        const id = try reader.readByte();
        const vel = try reader.readByte();
        std.debug.warn("aftertouch: {} {} {}\n", .{channel, id, vel});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.ControlChange)) {
        prev_status = status;
        const channel = status & 0x0f;
        const id = try reader.readByte();
        const val = try reader.readByte();
        std.debug.warn("control change: {} {} {}\n", .{channel, id, val});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.ProgramChange)) {
        prev_status = status;
        const channel = status & 0x0f;
        const id = try reader.readByte();
        std.debug.warn("program change: {} {}\n", .{channel, id});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.ChannelPressure)) {
        prev_status = status;
        const channel = status & 0x0f;
        const pressure = try reader.readByte();
        std.debug.warn("channel pressure: {} {}\n", .{channel, pressure});
    }

    if ((status & 0xf0) == @enumToInt(midiEvent.PitchBend)) {
        prev_status = status;
        const channel = status & 0x0f;
        const lsb = @as(u32, try reader.readByte()) & 0x7f;
        const msb = @as(u32, try reader.readByte()) & 0x7f;
        std.debug.warn("pitch bend: {}\n", .{msb << 7 | lsb});
    }

    return prev_status;
}

test "header" {
    const file = try std.fs.cwd().openFile("test.mid", .{
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
        std.debug.warn("track_id {s}\n", .{@bitCast([4]u8, track.id)});
        std.debug.warn("track_len {}\n", .{track.len});

        var prev_status: u8 = 0;

        while (true) {
            var delta: u32 = 0;
            var status: u8 = 0;
            delta = readValue(&file.reader()) catch |e| {
                break;
            };
            status = try file.reader().readByte();

            std.debug.warn("delta {}\n", .{delta});

            var allocator = std.testing.allocator;

            // continuing last command without the extra status byte
            if (status < 0x80) {
                status = prev_status;
                try file.seekBy(-1);
            }

            prev_status = try readMidiEvent(&file.reader(), status, prev_status);

            if ((status & 0xf0) == @enumToInt(midiEvent.SystemExclusive)) {
                prev_status= 0;
                if (status == 0xff) {
                    const ntype = try file.reader().readByte();
                    if (!try handleMeta(allocator, &file.reader(), ntype)) {
                        break;
                    }
                }

                if (status == 0xf0) {
                    std.debug.warn("system exclusive begin", .{});
                }

                if (status == 0xf7) {
                    std.debug.warn("system exclusive begin", .{});
                }
            }
        }

    }
}
