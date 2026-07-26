module claudtroller::calibrate;
import std::io;

// struct input_event on 64-bit Linux is 24 bytes:
//   struct timeval { long tv_sec; long tv_usec; }   // 16 bytes
//   ushort type; ushort code; int value;            //  8 bytes
struct InputEvent
{
    long   sec;
    long   usec;
    ushort type;
    ushort code;
    int    value;
}

// event types from linux/input-event-codes.h
const ushort EV_SYN = 0x00;
const ushort EV_KEY = 0x01;
const ushort EV_ABS = 0x03;

fn int main(String[] args)
{
    if (args.len < 2)
    {
        io::printn("usage: calibrate <device>   e.g. /dev/input/event2");
        return 1;
    }
    String path = args[1];

    File? maybe = file::open(path, "rb");
    if (catch err = maybe)
    {
        io::printfn("error: cannot open %s (%s) — are you in the 'input' group?", path, err);
        return 1;
    }
    File f = maybe;
    defer (void)f.close();

    io::printfn("reading events from %s  (Ctrl-C to stop)", path);

    InputEvent ev;
    usz evsize = @sizeof(ev);
    char[] buf = ((char*)&ev)[:evsize];
    while (true)
    {
        sz? got = f.read(buf);
        if (catch err = got)
        {
            io::printfn("read error: %s", err);
            return 1;
        }
        if (got == 0) break;
        if (got != (sz)evsize) continue;

        switch (ev.type)
        {
            case EV_KEY:
                String kind = ev.value == 1 ? "press" : (ev.value == 0 ? "release" : "repeat");
                io::printfn("KEY   code=%d  value=%d  (%s)", ev.code, ev.value, kind);
            case EV_ABS:
                io::printfn("ABS   code=%d  value=%d  (dpad/axis)", ev.code, ev.value);
            case EV_SYN:
                break; // frame separator; ignore
            default:
                io::printfn("type=%d code=%d value=%d", ev.type, ev.code, ev.value);
        }
    }
    return 0;
}
