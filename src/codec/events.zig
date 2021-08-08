pub const midiEventType = enum(u4) {
    NoteOff = 0x8,
    NoteOn = 0x9,
    Aftertouch = 0xa,
    ControlChange = 0xb,
    ProgramChange = 0xc,
    ChannelPressure = 0xd,
    PitchBend = 0xe,
};

pub const systemEventType = enum(u8) {
    SystemExclusive = 0xf0, // id: u7, data: []u8
    EndSystemExclusive = 0xf7,
    SongPosition = 0xf2, // position in beats lsb u7 msb u7
    SongSelect = 0xf3, // song u7
    TuneRequest = 0xf6, // song u7
    TimingClock = 0xf8,
    Start = 0xfa,
    Continue = 0xfb,
    Stop = 0xfc,
    // ActiveSensing = 0xFE,
    Reset = 0xff,
    _,
};

pub const metaEventType = enum(u8) {
    Sequence = 0x00,
    Text = 0x01,
    Copyright = 0x02,
    TrackName = 0x03,
    InstrumentName = 0x04,
    Lyrics = 0x05,
    Marker = 0x06,
    CuePoint = 0x07,
    ChannelPrefix = 0x20,
    EndOfTrack = 0x2f,
    SetTempo = 0x51,
    SMPTEOffset = 0x54,
    TimeSignature = 0x58,
    KeySignature = 0x59,
    SequencerSpecific = 0x7f,
};

pub const metaEvent = union(metaEventType) {
    Sequence: struct { len: u8 = 0, },
    Text: struct {
        /// length of string
        len: u8,
    },
    Copyright: struct {
        /// length of string
        len: u8,
    },
    TrackName: struct {
        /// length of string
        len: u8,
    },
    InstrumentName: struct {
        /// length of string
        len: u8,
    },
    Lyrics: struct {
        /// length of string
        len: u8,
    },
    Marker: struct {
        /// length of string
        len: u8,
    },
    CuePoint: struct {
        /// length of string
        len: u8,
    },
    ChannelPrefix: struct {
        /// discard bit after
        chan: u8,
    },
    /// discard bit after
    EndOfTrack: struct { },
    /// Set the tempo
    SetTempo: struct {
        tempo: u32,
    },
    /// 
    SMPTEOffset: struct {
        /// hour
        h: u8,
        /// minute
        m: u8,
        /// second
        s: u8,
        /// fractional frames
        fr: u8,
        /// fractional frames
        ff: u8,
    },
    TimeSignature: struct {
        /// numerator
        n: u8,
        // TODO: shift since denom is ^-2
        /// denominator
        d: u8,
        /// midi clock per metronome tick
        cpt: u8,
        /// 32nd notes per quarter note
        npq: u8,
    },
    KeySignature: struct {
        signature: u8,
        minor: u8,
    },
    SequencerSpecific: struct {
        len: u8,
    },
};

pub const Event = union(midiEventType) {
    /// Note off event
    /// Message sent when note is released
    NoteOff: struct {
        /// channel sent to
        chan: u4,
        /// id of the note
        id: u7,
        /// velocity of the note
        vel:u7,
    },
    /// Note on event
    /// Message sent when note is released
    NoteOn: struct {
        /// channel sent to
        chan: u4,
        /// id of the note
        id: u7,
        /// velocity of the note
        vel:u7,
    },
    /// Message sent when a key is pressed after bottoming out
    Aftertouch: struct {
        /// channel sent to
        chan: u4,
        /// id of the note
        id: u7,
        /// velocity of the note
        vel:u7,
    },
    /// Message sent when a controller value is changed
    ControlChange: struct {
        /// channel sent to
        chan: u4,
        /// controller number
        num: u7,
        /// new value for controller
        val: u7,
    },
    /// Message sent when the patch number changes
    ProgramChange: struct {
        /// channel sent to
        chan: u4,
        /// new program number
        num: u7
    },
    /// highest velocity of all pressed keys
    ChannelPressure: struct {
        /// channel sent to
        chan: u4,
        /// velocity
        vel: u7,
    },
    /// When the pitch wheel is used
    PitchBend: struct {
        /// channel sent to
        chan: u4,
        /// least significant 7 bits
        lsb: u7,
        /// most significant 7 bits
        msb: u7,
    },
};
