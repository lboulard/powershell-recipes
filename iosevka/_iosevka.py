#!/usr/bin/env python3
import re
import unittest
from dataclasses import dataclass, field
from enum import Enum
from functools import total_ordering

from itertools import groupby
from pathlib import Path

import os
import re
import sys
from contextlib import contextmanager
from itertools import takewhile
from pathlib import Path
from zipfile import ZipFile


#############################################################################
### version parsing


@total_ordering
@dataclass(frozen=True)
class Version:
    _version: [int]
    _pre: [str | int] = field(default_factory=list)
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


def extract_to_dest(dest, path):
    print(f"EXTRACT: {path} → {dest}")
    with ZipFile(path) as z:
        for name in z.namelist():
            print("\033[K  ", end="")
            print(dest / name, end="\r")
            z.extract(name, path=dest)
    print("\n")


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


def extract_all(files):
    version = extract_version(files[0])
    print("Using version " + version.full)
    # files = takewhile(lambda p: extract_version(p) == version, files)
    for path, dest in walk(version, files):
        extract_to_dest(dest, path)


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


def extract():
    if len(sys.argv) > 1:
        for path in sys.argv[1:]:
            with chwd(path) as wd:
                print(f"# entering {wd}")
                iosevka_extract()
                print(f"# leaving {wd}")
    else:
        iosevka_extract()
