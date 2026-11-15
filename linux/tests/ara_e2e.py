"""ara end to end through Fcitx5: a fresh fcitx5 with bada-linux's addon and ara (bada's engine and
its data) installed, driven over its D-Bus frontend (org.fcitx.Fcitx.InputMethod1) as an app's input
module drives it. Run by linux/test.sh, inside its own session bus.

What it checks is that bada's engine loads with its data and types through the host: muhenkan types
QWERTY, henkan composes and ranks (bada plain, the default), language keys switch, focus out commits,
and the state is published. The engine's behaviour itself is bada's tests' (engine/tests)."""

import dbus
import dbus.mainloop.glib

from common import KEYS, SHIFT, TextField, check, check_eq, finish, pump, read_state, wait_for

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
SERVICE = "org.fcitx.Fcitx5"
IME = "bada-ara"

# CapabilityFlag (fcitx-utils/capabilityflags.h)
PREEDIT, FORMATTED, SURROUNDING = 1 << 1, 1 << 4, 1 << 6



wait_for(lambda: bus.name_has_owner(SERVICE), 20, "fcitx5 on the bus")
controller = dbus.Interface(bus.get_object(SERVICE, "/controller"), "org.fcitx.Fcitx.Controller1")
im = dbus.Interface(bus.get_object(SERVICE, "/org/freedesktop/portal/inputmethod"), "org.fcitx.Fcitx.InputMethod1")

ims = {str(entry[0]): str(entry[1]) for entry in controller.AvailableInputMethods()}
check(IME in ims, f"{IME} is listed ({sorted(ims)})")
check_eq(ims.get(IME), "ara ime", "its display name")

signals = []
bus.add_signal_receiver(lambda ime, js: signals.append((str(ime), str(js))), signal_name="Changed",
                        dbus_interface="me.sjun.BadaLinux.State")


class Client:
    def __init__(self, program="e2e"):
        path, _ = im.CreateInputContext([("program", program), ("display", "x11:")])
        self.ic = dbus.Interface(bus.get_object(SERVICE, path), "org.fcitx.Fcitx.InputContext1")
        self.field = TextField()
        f = self.field
        bus.add_signal_receiver(lambda s: f.commit(str(s)), signal_name="CommitString",
                                dbus_interface="org.fcitx.Fcitx.InputContext1", path=path)
        bus.add_signal_receiver(lambda parts, cursor: f.set_preedit("".join(str(p[0]) for p in parts)),
                                signal_name="UpdateFormattedPreedit",
                                dbus_interface="org.fcitx.Fcitx.InputContext1", path=path)
        self.ic.SetCapability(dbus.UInt64(PREEDIT | FORMATTED | SURROUNDING))

    def focus(self):
        self.ic.FocusIn()
        pump()
        if str(controller.CurrentInputMethod()) != IME:
            controller.SetCurrentIM(IME)
            pump()

    def key(self, token, state=0, release=False):
        sym, code = KEYS[token]
        eaten = bool(self.ic.ProcessKeyEvent(dbus.UInt32(sym), dbus.UInt32(code + 8), dbus.UInt32(state),
                                             release, dbus.UInt32(0)))
        pump(0.05)
        if not eaten and not release:
            self.field.app_key(token, bool(state & SHIFT))
        return eaten

    def type(self, tokens):
        for t in tokens.split():
            self.key(t)
            self.key(t, release=True)


a = Client()
a.focus()
check_eq(str(controller.CurrentInputMethod()), IME, "current input method")

# ara starts in muhenkan (ime.json): QWERTY, typed by the host from its JIS table.
a.type("h e l l o Space")
check_eq(a.field.text, "hello ", "muhenkan types QWERTY")
check_eq(a.field.preedit, "", "nothing marked in muhenkan")
state = read_state(IME)
check(state is not None and state.get("mode") == "muhenkan" and state["host"]["ime"] == "ara",
      f"state file in muhenkan ({state})")

# 変換: henkan, bada plain alone (the engine's default; docs/layouts/16-bada-plain.md, deterministic):
# ㅇ ㅏ ㄴ ㄴ ㅕ ㅇ is 안녕. Space commits it.
a.type("henkan")
state = read_state(IME)
check(state is not None and state.get("mode") == "henkan", f"state file in henkan ({state})")
a.type("j f l l r j")
check_eq(a.field.preedit, "안녕", "henkan composes bada plain")
a.type("Space")
check_eq(a.field.preedit, "", "Space commits")
check_eq(a.field.text, "hello 안녕", "what showed is committed")

# Focus out commits what's staged.
a.type("j f l")
check_eq(a.field.preedit, "안", "staged")
a.ic.FocusOut()
pump()
check_eq(a.field.text, "hello 안녕안", "focus out commits")

# 無変換: back to muhenkan, for every input context.
b = Client(program="other")
b.focus()
b.type("muhenkan a b c")
check_eq(b.field.text, "abc", "無変換: muhenkan again")
check(any('"henkan"' in js for _, js in signals) and any('"muhenkan"' in js for _, js in signals),
      "Changed signals carried both modes")

finish("ara e2e")
