
Cascadia Mono is Cascadia Code without ligatures.
_________________________________________________________________

TTF "classic": ttf/static/*.tff
TTF "variable": ttf/*.ttf

Never install both kind!
fonts may not be usable depending of which version is seen first.

If usage limited to Microsoft Software, you can install "variable" kind.

_________________________________________________________________

When you install Windows Terminal, installation register as provider for
variable Cascadia and Cascadia Mono fonts. Both fonts are accessible by
CMD.EXE (conhost.exe). Better use PL variants for pretty prompt.

WARNING: Installs Cascadia and Cascadia Mono as user only fonts only if
Terminal is not installed.
_________________________________________________________________

Cascadia PL/Cascadia Mono PL (add Powerline Symbols) are not provided by
Windows Terminal. For CMD.EXE use (conhost.exe), install as system font,
not user only fonts! Use "classic" fonts for most support by applications.
