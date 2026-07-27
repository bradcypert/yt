module claudtroller;
import std::io;

// ------------------------------------------------------------------
// struct input_event (24 bytes on 64-bit Linux)
// ------------------------------------------------------------------
struct InputEvent
{
    long      sec;
    long      usec;
    EventType type;
    InputCode code;
    int       value;
}

constdef EventType : ushort
{
    SYN = 0x00,
    KEY = 0x01,
    ABS = 0x03
}

typedef InputCode @constinit = ushort;

// ------------------------------------------------------------------
// gamepad codes (from calibration of the 12bd:d015 "2Axes 11Keys" pad)
// ------------------------------------------------------------------
const InputCode PAD_X      = 304;
const InputCode PAD_A      = 305;
const InputCode PAD_B      = 306;
const InputCode PAD_Y      = 307;
const InputCode PAD_L      = 308;
const InputCode PAD_R      = 309;
const InputCode PAD_SELECT = 312;
const InputCode PAD_START  = 313;
const InputCode ABS_X      = 0;
const InputCode ABS_Y      = 1;

// ------------------------------------------------------------------
// Linux keyboard keycodes we emit (linux/input-event-codes.h)
// ------------------------------------------------------------------
const InputCode KEY_ESC        = 1;
const InputCode KEY_TAB        = 15;
const InputCode KEY_ENTER      = 28;
const InputCode KEY_LEFTSHIFT  = 42;
const InputCode KEY_SPACE      = 57;
const InputCode KEY_UP         = 103;
const InputCode KEY_PAGEUP     = 104;
const InputCode KEY_LEFT       = 105;
const InputCode KEY_RIGHT      = 106;
const InputCode KEY_DOWN       = 108;
const InputCode KEY_PAGEDOWN   = 109;

// ------------------------------------------------------------------
// uinput ioctls (precomputed _IO/_IOW values, base 'U'=0x55)
// ------------------------------------------------------------------
const ulong UI_SET_EVBIT   = 0x40045564;
const ulong UI_SET_KEYBIT  = 0x40045565;
const ulong UI_DEV_SETUP   = 0x405c5503;  // _IOW('U',3, sizeof(uinput_setup)=92)
const ulong UI_DEV_CREATE  = 0x5501;
const ulong UI_DEV_DESTROY = 0x5502;
const ushort BUS_USB       = 0x03;

const CInt O_RDONLY = 0;
const CInt O_WRONLY = 1;

struct InputId
{
    ushort bustype;
    ushort vendor;
    ushort product;
    ushort version;
}

struct UinputSetup
{
    InputId  id;
    char[80] name;
    uint     ff_effects_max;
}

// ------------------------------------------------------------------
// libc bindings (names match the C symbols, so no rename attribute).
// ioctl is variadic, as in the C3 stdlib.
// ------------------------------------------------------------------
extern fn CInt open(char* path, CInt flags);
extern fn sz   read(CInt fd, void* buf, usz n);
extern fn sz   write(CInt fd, void* buf, usz n);
extern fn CInt close(CInt fd);
extern fn CInt ioctl(CInt fd, ulong request, ...);

// ------------------------------------------------------------------
// uinput emit helpers
// ------------------------------------------------------------------
fn void emit(CInt fd, EventType type, InputCode code, int value)
{
    InputEvent ev;
    ev.type  = type;
    ev.code  = code;
    ev.value = value;
    write(fd, &ev, @sizeof(ev));
}

fn void key(CInt fd, InputCode code, int down)
{
    emit(fd, KEY, code, down);
    emit(fd, SYN, 0, 0);
}

fn void tap(CInt fd, InputCode code)
{
    key(fd, code, 1);
    key(fd, code, 0);
}

fn void shift_tab(CInt fd)
{
    emit(fd, KEY, KEY_LEFTSHIFT, 1); emit(fd, SYN, 0, 0);
    emit(fd, KEY, KEY_TAB, 1);       emit(fd, SYN, 0, 0);
    emit(fd, KEY, KEY_TAB, 0);       emit(fd, SYN, 0, 0);
    emit(fd, KEY, KEY_LEFTSHIFT, 0); emit(fd, SYN, 0, 0);
}

fn CInt setup_uinput()
{
    CInt fd = open("/dev/uinput", O_WRONLY);
    if (fd < 0) return -1;

    ioctl(fd, UI_SET_EVBIT, (CInt)EventType.KEY);
    ioctl(fd, UI_SET_EVBIT, (CInt)EventType.SYN);

    InputCode[*] keys = {
        KEY_ESC, KEY_TAB, KEY_ENTER, KEY_LEFTSHIFT, KEY_SPACE,
        KEY_UP, KEY_PAGEUP, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_PAGEDOWN,
    };
    foreach (k : keys) ioctl(fd, UI_SET_KEYBIT, (CInt)k);

    UinputSetup us;
    us.id.bustype = BUS_USB;
    us.id.vendor  = 0xc1a0;
    us.id.product = 0x0001;
    String label = "claudtroller";
    foreach (i, c : label) us.name[i] = c;

    ioctl(fd, UI_DEV_SETUP, (void*)&us);
    ioctl(fd, UI_DEV_CREATE, 0);
    return fd;
}

// map an analog axis position to a discrete direction: -1 / 0 / +1
fn int axis_dir(int value)
{
    if (value < 64) return -1;
    if (value > 192) return 1;
    return 0;
}

fn int main(String[] args)
{
    String dev = "/dev/input/by-id/usb-12bd_2Axes_11Keys_Game_Pad-event-joystick";
    if (args.len >= 2) dev = args[1];

    CInt gp = open(dev, O_RDONLY);
    if (gp < 0)
    {
        io::printfn("cannot open gamepad %s (in the 'input' group?)", dev);
        return 1;
    }

    CInt ui = setup_uinput();
    if (ui < 0)
    {
        io::printn("cannot open /dev/uinput (need write access — udev rule / group)");
        return 1;
    }
    io::printn("claudtroller running.  Select = toggle on/off,  Ctrl-C to quit.");

    bool enabled = true;
    int xdir = 0;
    int ydir = 0;

    InputEvent ev;
    while (read(gp, &ev, @sizeof(ev)) == @sizeof(ev))
    {
        switch
        {
            case ev.type == KEY:
                if (ev.code == PAD_SELECT && ev.value == 1)
                {
                    enabled = !enabled;
                    io::printfn("[%s]", enabled ? "enabled" : "disabled");
                    continue;
                }
                if (!enabled || ev.value == 2) continue; // ignore autorepeat / disabled
                bool down = ev.value == 1;
                switch (ev.code)
                {
                    case PAD_A:     if (down) tap(ui, KEY_ENTER);
                    case PAD_START: if (down) tap(ui, KEY_ENTER);
                    case PAD_B:     if (down) tap(ui, KEY_ESC);
                    case PAD_X:     if (down) shift_tab(ui);
                    case PAD_Y:     key(ui, KEY_SPACE, down ? 1 : 0); // push-to-talk (hold)
                    case PAD_L:     if (down) tap(ui, KEY_PAGEUP);
                    case PAD_R:     if (down) tap(ui, KEY_PAGEDOWN);
                    default:        break;
                }
            case ev.type == ABS && enabled:
                switch (ev.code)
                {
                    case ABS_X:
                        int nd = axis_dir(ev.value);
                        if (nd == xdir) break;
                        if (xdir == -1) key(ui, KEY_LEFT, 0);
                        if (xdir == 1)  key(ui, KEY_RIGHT, 0);
                        if (nd == -1)   key(ui, KEY_LEFT, 1);
                        if (nd == 1)    key(ui, KEY_RIGHT, 1);
                        xdir = nd;
                    case ABS_Y:
                        int nd = axis_dir(ev.value);
                        if (nd == ydir) break;
                        if (ydir == -1) key(ui, KEY_UP, 0);
                        if (ydir == 1)  key(ui, KEY_DOWN, 0);
                        if (nd == -1)   key(ui, KEY_UP, 1);
                        if (nd == 1)    key(ui, KEY_DOWN, 1);
                }
        }
    }

    ioctl(ui, UI_DEV_DESTROY, 0);
    close(ui);
    close(gp);
    return 0;
}






