// import all tests in the folder and run em
test "test suite" {
    const zutil = @import("zutil");

    _ = zutil.containers.Ref;
    //_ = zutil.containers.RingBuffer;
}
