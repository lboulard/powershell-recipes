# Silent installation of Python

Made for multiple installation of python on same machine.

Works and tested with Python 3.5 to 3.13.

## Installation

Copy all dosbatch and xml files next to installer named like
`Python-3.x.y-amd64.exe`.

## Configure default python for script launch

For default python, as administrator, run `unattend-default.bat` to create file
`unattend.xml` needed for silent installation.

For all other python installations, as administrator, run
`unattend-not-default.bat` to create file `unattend.xml` needed for silent
installation.

See [Caveats](#Caveats) if you need to change default python version on already
configured computer.

## Silent installation

For each python that needs to be installed, run `python-silent-install.bat`.

## Silent uninstallation

For each python that needs to be removed from computer, run
`python-silent-install.bat`.

## Caveats

- Installation of Debug files and symbols required internet connection as they
  are mot included in standalone installers.

Changing a non-default installation to become default installation does not
work when minor version is not changed. Installers seems to ignore new settings
on existing installation. Issue observed when going from version 3.6 to
existing version 3.7.

- To change default python version from `3.N` to `3.N+1`:
  - version `3.N` must be uninstalled first
  - version `3.N+1` must be uninstalled after
  - change `unattend.xml` of version `3.N` to `unattend-not-default.xml`
  - change `unattend.xml` of version `3.N+1` to `unattend-default.xml`
  - install version `3.N`, then version `3.N+1`
