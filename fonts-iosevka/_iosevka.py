#!/usr/bin/env python3
import os
import re
import sys
import unittest
from contextlib import contextmanager
from dataclasses import dataclass, field
from enum import Enum
from functools import total_ordering
from itertools import groupby, takewhile
from pathlib import Path
from zipfile import ZipFile

#############################################################################
### version parsing


@total_ordering
@dataclass(frozen=True)
class Version:
    _version: list[int]
    _pre: list[str | int] = field(default_factory=list)
    _full: str = ""

    @property
    def version(self) -> str:
        return ".".join(str(x) for x in self._version)

    @property
    def pre(self) -> str:
        return ".".join(str(x) for x in self._pre)

    @property
    def full(self) -> str:
        s = self._full
        if not s:
            s = self.version()
            if self._pre:
                s += "-" + self.pre()
        return s

    def __lt__(self, version: "Version") -> bool:
        if isinstance(version, Version):
            if self._version != version._version:
                return self._version < version._version
            if self._pre and not version._pre:
                return True
            return self._pre < version._pre
        return NotImplemented

    def __eq__(self, version: "Version") -> bool:
        if isinstance(version, Version):
            return self._version == version._version and self._pre == version._pre
        return NotImplemented


def tokenize(s):
    return [
        int(x) if x.isdigit() else x.lower()
        for x in re.split(r"([0-9]+|\.|-|_|\s+)", str(s))
        if x
    ]


def _is_pre_release(token):
    return token in ("alpha", "beta", "rc")


def _is_int(s):
    return isinstance(s, int)


def _is_dot(s):
    return s == "."


def _is_hyphen(s):
    return s == "-"


class State(Enum):
    ERROR = -1
    START = 0
    MAJOR = 1
    MINOR_DOT = 2
    MINOR = 3
    PATCH_DOT = 4
    PATCH = 5
    PRE_START = 10
    PRE = 11
    PRE_DOT = 12
    END = 99

    def is_final(self):
        return self in (State.END, State.ERROR)

    def is_transient(self):
        return self in (State.START, State.END, State.ERROR)

    def is_dot(self):
        return self in (State.MINOR_DOT, State.PATCH_DOT, State.PRE_DOT)

    def is_end(self):
        return self == State.END

    def is_error(self):
        return self == State.ERROR

    def is_version(self):
        return self in (State.MAJOR, State.MINOR, State.PATCH)

    def is_pre(self):
        return self == State.PRE


TRANSITIONS = {
    State.START: [(State.MAJOR, _is_int), (State.START, None)],
    State.MAJOR: [(State.MINOR_DOT, _is_dot), (State.START, None)],
    State.MINOR_DOT: [(State.MINOR, _is_int), (State.START, None)],
    State.MINOR: [(State.PATCH_DOT, _is_dot), (State.END, None)],
    State.PATCH_DOT: [(State.PATCH, _is_int), (State.END, None)],
    State.PATCH: [
        (State.PRE_START, _is_hyphen),
        (State.PRE, _is_pre_release),
        (State.END, None),
    ],
    State.PRE_START: [(State.PRE, _is_pre_release)],
    State.PRE: [
        (State.PRE, _is_int),
        (State.PRE_DOT, _is_dot),
        (State.PRE_DOT, _is_hyphen),
        (State.END, None),
    ],
    State.PRE_DOT: [(State.PRE, _is_int), (State.END, None)],
    State.ERROR: [(State.ERROR, None)],
    State.END: [(State.MAJOR, _is_int), (State.END, None)],
}


class ExtractVersion:
    def __init__(self):
        self.state = State.START
        self.version = []
        self.pre = []
        self.text = ""
        self._error = TRANSITIONS[State.ERROR]

    def reset(self) -> None:
        self.version = []
        self.pre = []
        self.text = ""

    def is_error(self) -> bool:
        return self.state.is_error()

    def is_done(self) -> bool:
        return self.state.is_final()

    def is_found(self) -> bool:
        return self.state.is_end()

    def next(self, token) -> None:
        state, previous = State.ERROR, self.state
        for _next, test in TRANSITIONS.get(self.state, self._error):
            if _next.is_transient() or test(token):
                state = _next
                break
        # print(f"{token=!r:<15} {state=} {previous=} {self.text=}")
        if state == State.MAJOR and previous.is_transient():
            self.reset()
        if not state.is_transient():
            self.text += str(token)
        elif state.is_end() and previous.is_dot():
            # remove final unused dot
            self.text = self.text[:-1]
        # collect
        if state.is_version():
            self.version.append(token)
        elif state.is_pre():
            self.pre.append(token)
        self.state = state

    def finish(self) -> list[list[int], list[str | int], str]:
        # last round
        self.next("")
        assert self.state == State.END
        return [self.version, self.pre, self.text]


def extract_version_fsm(s) -> list[list[int], list[str | int], str]:
    extract = ExtractVersion()
    for token in tokenize(s):
        extract.next(token)
        if extract.is_error():
            break
    if extract.is_done():
        return extract.finish()
    return []


VERSION_RE = re.compile(
    r"""
    (?P<version>\d+\.\d+(\.\d+)?)               # version like 1.2 or 1.2.3
    [_-]?(?P<pre>(alpha|beta|rc)([\.-]?\d+)?)?  # pre like -alpha1, _rc.2
    """,
    re.I | re.A | re.X,
)


PRE_RE = re.compile(r"([0-9]+|\.|-|_|\s+)")


def extract_version_re(s) -> list[list[int], list[str | int], str]:
    version, pre, full = [], [], ""
    for m in VERSION_RE.finditer(s):
        version = [int(x) for x in m["version"].split(".")]
        pre = (
            [
                int(x) if x.isdigit() else x.lower()
                for x in PRE_RE.split(m["pre"])
                if x and x not in r".-_"
            ]
            if m["pre"]
            else []
        )
        full = m[0]
    return [version, pre, full] if version else []


#############################################################################
### unittest for version parsing


class ExtractVersionsTest(unittest.TestCase):
    extract_fn = [extract_version_fsm, extract_version_re]

    def test_tokenize(self):
        self.assertEqual(
            tokenize("Hello  world 123_3.4_a-xyz.ext"),
            [
                "hello",
                "  ",
                "world",
                " ",
                123,
                "_",
                3,
                ".",
                4,
                "_",
                "a",
                "-",
                "xyz",
                ".",
                "ext",
            ],
        )

    def test_extract_version_1_2(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project-1.2.ext.gz"),
                    [[1, 2], [], "1.2"],
                    "version 1.2 is expected",
                )

    def test_extract_version_1_2_3(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project-1.2.3.ext.gz"),
                    [[1, 2, 3], [], "1.2.3"],
                    "version 1.2.3 is expected",
                )

    def test_extract_version_1_2_3_alpha(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project-1.2.3-alpha.ext.gz"),
                    [[1, 2, 3], ["alpha"], "1.2.3-alpha"],
                    "version 1.2.3-alpha is expected",
                )

    def test_extract_version_1_2_3_alpha_1(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project-1.2.3-alpha1.ext.gz"),
                    [[1, 2, 3], ["alpha", 1], "1.2.3-alpha1"],
                    "version 1.2.3-alpha1 is expected",
                )

    def test_extract_version_1_2_3_alpha_hyphen_1(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project-1.2.3-alpha-1.ext.gz"),
                    [[1, 2, 3], ["alpha", 1], "1.2.3-alpha-1"],
                    "version 1.2.3-alpha-1 is expected",
                )

    def test_major_in_middle(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project25-1.2.3.ext.gz"),
                    [[1, 2, 3], [], "1.2.3"],
                    "version 1.2.3 is expected",
                )

    def test_major_minor_in_middle(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("project1.25-1.2.3.ext.gz"),
                    [[1, 2, 3], [], "1.2.3"],
                    "version 1.2.3 is expected",
                )

    def test_iosevka_beta(self):
        for fn in self.extract_fn:
            with self.subTest(msg=fn.__name__, extract_version=fn):
                self.assertEqual(
                    fn("PkgTTC-IosevkaEtoile-28.0.0-beta.3.zip"),
                    [[28, 0, 0], ["beta", 3], "28.0.0-beta.3"],
                    "version 28.0.0-beta.3 is expected",
                )


class VersionTest(unittest.TestCase):
    def test_equals(self):
        versionA = Version([1, 2], ["alpha"])
        versionB = Version([1, 2], ["beta"])
        versionR = Version([1, 2], ["rc"])
        version1 = Version([1, 2])
        version2 = Version([1, 2, 3])
        self.assertEqual(versionA, versionA)
        self.assertNotEqual(versionA, versionB)
        self.assertNotEqual(versionA, versionR)
        self.assertEqual(versionB, versionB)
        self.assertNotEqual(versionB, versionR)
        self.assertEqual(versionR, versionR)
        self.assertNotEqual(version1, versionR)
        self.assertEqual(version1, version1)
        self.assertNotEqual(version1, version2)
        self.assertEqual(version2, version2)

    def test_order(self):
        versionA0 = Version([1, 2], ["alpha"])
        versionA1 = Version([1, 2], ["alpha", 1])
        versionB0 = Version([1, 2], ["beta"])
        versionB1 = Version([1, 2], ["beta", 1])
        versionR0 = Version([1, 2], ["rc"])
        versionR1 = Version([1, 2], ["rc", 1])
        version_1 = Version([1, 2])
        version_2 = Version([1, 2, 3])
        self.assertLess(versionA0, versionA1)
        self.assertLess(versionA1, versionB0)
        self.assertLess(versionB0, versionB1)
        self.assertLess(versionB1, versionR0)
        self.assertLess(versionR0, versionR1)
        self.assertLess(versionR1, version_1)
        self.assertLess(version_1, version_2)
        self.assertLess(versionR1, version_2)
        self.assertLess(versionR0, version_1)
        self.assertLess(versionB1, version_1)
        self.assertLess(versionB0, version_1)
        self.assertLess(versionA1, version_1)
        self.assertLess(versionA0, version_1)


_extract_version = extract_version_fsm


def extract_version(s) -> None | Version:
    m = _extract_version(s)
    if m:
        return Version(*m)
    return None


#############################################################################
### cleanup


def iosevka_cleanup(files):
    last_version = extract_version(files[0])
    for version, g in groupby(
        extract_version(p) for p in files if extract_version(p) != last_version
    ):
        backups = set()
        for path, dest in walk(version, files):
            if dest.exists():
                backups.add(dest)
            if path.exists():
                backups.add(path)
        if backups:
            backup_dir = Path(version.full)
            backup_dir.mkdir(exist_ok=True)
            for path in backups:
                print(f"{path} → {backup_dir / path.name}")
                path.replace(backup_dir / path.name)


def clean_up():
    files = sorted(Path(".").glob("*iosevka*.zip"), key=extract_version, reverse=True)
    if files:
        iosevka_cleanup(files)
    else:
        print("No files to cleanup")


#############################################################################
### extract

from datetime import datetime
from queue import Full, Queue
from threading import Condition, Thread


class Limiter:
    def __init__(self, size):
        self.bound = size
        self.max = size
        self._cv = Condition()

    def acquire(self, n):
        cv = self._cv
        with cv:
            while self.bound < n:
                cv.wait()
            self.bound -= n

    def release(self, n):
        with self._cv:
            self.bound += n
            self._cv.notify()

    def reset(self):
        with self._cv:
            self.bound = self.max
            self._cv.notify()


# no more than 256MB of data in queues
LIMIT = Limiter(256 << 20)


def sanitize_path(name):
    pathsep = os.path.sep
    name = name.replace("/", pathsep)
    if os.path.altsep:
        name = name.replace(os.path.altsep, pathsep)
    name = os.path.splitdrive(name)[1]
    bad = ("", os.path.curdir, os.path.pardir)
    arcname = (x for x in name.split(pathsep) if x not in bad)
    table = str.maketrans(':<>|"?*', "_______")
    arcname = (x.translate(table) for x in arcname)
    arcname = (x.rstrip(" .") for x in arcname)
    name = os.path.sep.join(x for x in arcname if x)
    return name


def write_file(pathname, mtime_ns, queue):
    parents = os.path.dirname(pathname)
    if parents and not os.path.exists(parents):
        os.makedirs(parents)
    with open(pathname, "wb") as w:
        data = queue.get()
        while data:
            w.write(data)
            LIMIT.release(len(data))
            data = queue.get()
    try:
        st = os.stat(pathname)
        os.utime(pathname, ns=(st.st_atime_ns, mtime_ns))
    except (OverflowError, OSError):
        pass


def date_time_ns(date_time):
    dt = datetime(*date_time)
    return int(dt.timestamp() * 10**9)


def write_files_from_archive(dest, queue):
    end = ""
    try:
        while True:
            filename, date_time = queue.get()
            if not filename:
                break
            filename = sanitize_path(filename)
            print("\033[K  ", end="")
            pathname = os.fspath(dest / filename)
            print(pathname, end="\r")
            end = "\n"
            mtime_ns = date_time_ns(date_time)
            write_file(pathname, mtime_ns, queue)
    finally:
        print(end)


def write_thread(queue):
    try:
        while True:
            dest, archive = queue.get()
            if not archive:
                break
            print(f"EXTRACT: {archive} → {dest}")
            write_files_from_archive(dest, queue)
    except:
        LIMIT.reset()
        raise


def extract_to_file(source, queue):
    buf = source.read(65536)
    while buf:
        LIMIT.acquire(len(buf))
        queue.put(buf, timeout=10)
        buf = source.read(65536)


def extract_to_dest(dest, path, queue):
    queue.put((dest, path), timeout=10)
    try:
        with ZipFile(path) as z:
            for zi in z.infolist():
                queue.put((zi.filename, zi.date_time), timeout=10)
                try:
                    with z.open(zi, pwd=dest) as source:
                        extract_to_file(source, queue)
                finally:
                    # end of data flow
                    queue.put(b"", timeout=10)
    finally:
        # no more files to write
        queue.put((None, None), timeout=10)


def die(*args, out=sys.stderr):
    print("** FATAL: ", end="", file=out)
    print(*args, file=out)
    sys.exit(1)


def walk(version, files):
    ttf_dest = Path("ttf-iosevka-" + version.full)
    ttc_dest = Path("ttc-iosevka-" + version.full)
    for path in (p for p in files if extract_version(p) == version):
        if "ttf-" in path.name or "TTF-" in path.name:
            yield (path, ttf_dest)
        elif "ttc-" in path.name or "TTC-" in path.name:
            yield (path, ttc_dest)


def extract_all(files, root_path=None):
    version = extract_version(files[0])
    print("Using version " + version.full)
    # files = takewhile(lambda p: extract_version(p) == version, files)
    queue = Queue()
    # start write in another thread
    wq = Thread(target=write_thread, args=(queue,))
    wq.start()
    try:
        for path, dest in walk(version, files):
            if root_path:
                dest = root_path / dest
            extract_to_dest(dest, path, queue)
    except Full:
        print("write thread failed!", file=sys.stderr)
        raise
    finally:
        # exit write thread with no more archive to write
        queue.put((None, None), timeout=10)
        wq.join()


def iosevka_extract():
    # requires Python 3.12 for "case_sensitive" keyword argument
    files = list(Path(".").glob("*iosevka*.zip", case_sensitive=False))
    files = sorted(files, key=extract_version, reverse=True)
    if not files:
        die("no files found")
    extract_all(files)


@contextmanager
def chwd(path):
    cwd = os.getcwd()
    try:
        wd = Path(path)
        if wd.is_dir():
            os.chdir(wd)
            yield wd
        else:
            die(f"{wd} not a directory")
    finally:
        os.chdir(cwd)


def extract(dest=None):
    if dest:
        with chwd(dest) as wd:
            print(f"# entering {wd}")
            iosevka_extract()
            print(f"# leaving {wd}")
    else:
        iosevka_extract()


#############################################################################
### install fonts for user account on Windows

import ctypes
import ctypes.wintypes as wintypes

# Load gdi32.dll
gdi32 = ctypes.WinDLL("gdi32.dll")

# Define constants
FRINFO_DESCRIPTION = 1  # Query for font descriptions
FRINFO_FONTNAMES = 2  # Query for font names
FR_PRIVATE = 0x10

# Function prototypes
AddFontResourceExW = gdi32.AddFontResourceExW
AddFontResourceExW.argtypes = [wintypes.LPCWSTR, wintypes.UINT, wintypes.LPVOID]
AddFontResourceExW.restype = wintypes.INT

RemoveFontResourceExW = gdi32.RemoveFontResourceExW
RemoveFontResourceExW.argtypes = [wintypes.LPCWSTR, wintypes.UINT, wintypes.LPVOID]
RemoveFontResourceExW.restype = wintypes.BOOL

GetFontResourceInfoW = gdi32.GetFontResourceInfoW
GetFontResourceInfoW.argtypes = [
    wintypes.LPCWSTR,  # lpPathname (path to the font file)
    ctypes.POINTER(ctypes.c_uint),  # cbBuffer (pointer to size of the buffer)
    wintypes.LPVOID,  # lpBuffer (pointer to the buffer to receive information)
    wintypes.DWORD,  # dwQueryType (type of information to retrieve)
]
GetFontResourceInfoW.restype = wintypes.BOOL


def get_font_name_from_file(font_file_path):
    font_file_path = str(font_file_path)
    # Check if the font file exists
    if not os.path.exists(font_file_path):
        return []

    # Load the font(s) from the file (works for both TTF and TTC)
    loaded_fonts = AddFontResourceExW(font_file_path, FR_PRIVATE, None)
    if loaded_fonts <= 0:
        return []

    font_name = []
    try:
        # Query the required buffer size for the font names
        buffer_size = ctypes.c_uint(0)
        result = GetFontResourceInfoW(
            font_file_path, ctypes.byref(buffer_size), None, FRINFO_DESCRIPTION
        )

        if result:
            # Allocate buffer to hold the font names
            buffer = ctypes.create_unicode_buffer(buffer_size.value)

            # Retrieve the font names
            if GetFontResourceInfoW(
                font_file_path, ctypes.byref(buffer_size), buffer, FRINFO_DESCRIPTION
            ):
                # Convert the buffer to a Python string
                font_name = buffer.value
    finally:
        # Remove the font resource
        RemoveFontResourceExW(font_file_path, FR_PRIVATE, None)

    return font_name


def set_registry_for_fonts(files, user_fonts_path):
    import winreg

    version = extract_version(files[0])
    ttf_dest = Path("ttf-iosevka-" + version.full)
    hkey = winreg.OpenKey(
        winreg.HKEY_CURRENT_USER,
        "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts",
        access=winreg.KEY_SET_VALUE,
    )
    end = ""
    try:
        clear_eol = "\033[K"
        for font_path in (user_fonts_path / ttf_dest).glob(
            "*.ttf", case_sensitive=False
        ):
            font_name = get_font_name_from_file(font_path)
            if font_name:
                name = font_name + " (TrueType)"
                print(f"{clear_eol}REGISTER: '{name}'", end="\r")
                end = "\n"
                winreg.SetValueEx(hkey, name, 0, winreg.REG_SZ, str(font_path))
            else:
                print(f"{clear_eol}REGISTER: name not found for '{font_path}'")
    finally:
        winreg.CloseKey(hkey)
        print(end=end)


def install(register_only=False):
    # requires Python 3.12 for "case_sensitive" keyword argument
    files = list(Path(".").glob("*ttf*iosevka*.zip", case_sensitive=False))
    files = sorted(files, key=extract_version, reverse=True)
    if not files:
        die("no files found")

    local_app_data = os.getenv("LOCALAPPDATA", "")
    if not local_app_data:
        local_app_data = os.path.expanduser("~/Local Settings/Application Data")
    user_fonts = Path(local_app_data) / "Microsoft" / "Windows" / "Fonts"

    if not register_only:
        print(f"# installing font in {user_fonts}")
        extract_all(files, root_path=user_fonts)
    set_registry_for_fonts(files, user_fonts)

    # Registry modification (pseudo-code in comments for reference)
    # For TTC files, you would create a REG_SZ key in the registry under:
    # HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Fonts
    # The key name should be "${fontName} (TrueType)" and the value should be the absolute path to the font.


#############################################################################
### Create [Files] section for Inno Setup

# Source: "OZHANDIN.TTF"; DestDir: "{autofonts}"; FontInstall: "Oz Handicraft BT"; \
#  Flags: ignoreversion comparetimestamp uninsrestartdelete


def inno_file_line(writer, font_path, ttf_dest):
    font_name = get_font_name_from_file(font_path)
    if font_name:
        print(f'Source: "{font_path}"; ', end="", flush=False, file=writer)
        print(
            f'DestDir: "{{autofonts}}\\{ttf_dest}"; ', end="", flush=False, file=writer
        )
        print(f'FontInstall: "{font_name}"; ', end="", flush=False, file=writer)
        print("Flags: ignoreversion comparetimestamp uninsrestartdelete", file=writer)
    else:
        print(f'// Source: "{font_path}"; // cannot find font name', file=writer)


def inno():
    # requires Python 3.12 for "case_sensitive" keyword argument
    files = list(Path(".").glob("*ttf*iosevka*.zip", case_sensitive=False))
    files = sorted(files, key=extract_version, reverse=True)
    if not files:
        die("no files found")

    import tempfile

    with tempfile.TemporaryDirectory() as temp_dir:
        extract_all(files, root_path=temp_dir)
        version = extract_version(files[0])
        ttf_dest = Path("ttf-iosevka-" + version.full)

        Path("version.inc.iss").write_text(f'#define MyAppVersion "{version.full}"')
        with open("files.inc.iss", "w+") as writer:
            for font_path in (temp_dir / ttf_dest).glob("*.ttf", case_sensitive=False):
                inno_file_line(writer, font_path, ttf_dest)
        os.system('"C:/Program Files (x86)/Inno Setup 6/ISCC.exe" installer.iss')


if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser(prog="_iosevka")
    sub = parser.add_subparsers(help="choose one of commands")
    # extract
    extract_cmd = sub.add_parser("extract", help="extract zip files in current folder")
    extract_cmd.add_argument("dest", nargs="?", help="optional destination path")
    extract_cmd.set_defaults(func=extract)
    # clean up
    cleanup_cmd = sub.add_parser("cleanup", help="move in folders older revisions")
    cleanup_cmd.set_defaults(func=clean_up)
    # install
    install_cmd = sub.add_parser("install", help="user install of fonts in registry")
    install_cmd.add_argument(
        "-r",
        "--register-only",
        action="store_true",
        help="only update registry for current installed fonts",
    )
    # inno setupo based installer creation
    cleanup_cmd = sub.add_parser(
        "inno", help="create an installer based on Inno Setup 6"
    )
    cleanup_cmd.set_defaults(func=inno)
    #
    install_cmd.set_defaults(func=install)
    #
    args = parser.parse_args()
    opts, func = vars(args), args.func
    del opts["func"]
    func(**opts)
