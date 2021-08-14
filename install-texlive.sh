#!/usr/bin/env bash
#
# This script installs a local, user space TeX Live suite.  There are a lot of packages
# to download, so it will take about an hour to install depending on your internet
# speed and computer system.
#
# Author: Gary Hammock (https://ghammock.dev)
# Repository: https://github.com/ghammock/texlive_userspace
#
# SPDX-License-Identifier: MIT
#
# License
# =======
# Copyright (c) 2021 Gary Hammock
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# References
# ==========
# https://www.tug.org/texlive/doc/tlmgr.html
# https://www.tug.org/texlive/doc/texlive-en/texlive-en.html
# https://www.tug.org/texlive/doc/install-tl.html
#

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

start_dir=$(pwd)

mkdir -p ${HOME}/src
cd ${HOME}/src

# Download the installer and extract it.
echo "Downloading the current TeX Live installer"
curl -fsSLO https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xf install-tl-unx.tar.gz

# Extract the 4 digit year (e.g. 2021) from the directory name
tl_release=$(ls | grep install-tl-20* | sed -E 's/install-tl-(20[0-9]{2}).*/\1/g')

# Create the installation path
mkdir -p ${HOME}/local/lib/texlive/${tl_release}

# Write out the installation profile file
# see: https://www.tug.org/texlive/doc/install-tl.html#PROFILES
cd $(ls | grep install-tl-20*)
cat << EOF > texlive.profile
selected_scheme scheme-custom
TEXDIR ${HOME}/local/lib/texlive/${tl_release}
TEXMFCONFIG ${HOME}/.texlive/texmf-config
TEXMFHOME ${HOME}/.texlive/texmf
TEXMFLOCAL ${HOME}/local/lib/texlive/texmf-local
TEXMFSYSCONFIG ${HOME}/local/lib/texlive/${tl_release}/texmf-config
TEXMFSYSVAR ${HOME}/local/lib/texlive/${tl_release}/texmf-var
TEXMFVAR ${HOME}/.texlive/texmf-var
collection-basic 1
collection-bibtexextra 1
collection-binextra 1
collection-context 1
collection-fontsextra 1
collection-fontsrecommended 1
collection-fontutils 1
collection-formatsextra 1
collection-games 1
collection-humanities 1
collection-langenglish 1
collection-langgreek 1
collection-latex 1
collection-latexextra 1
collection-latexrecommended 1
collection-luatex 1
collection-mathscience 1
collection-metapost 1
collection-music 1
collection-pictures 1
collection-plaingeneric 1
collection-pstricks 1
collection-publishers 1
collection-texworks 1
collection-xetex 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 1
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 1
tlpdbopt_post_code 1
tlpdbopt_sys_bin ${HOME}/local/bin
tlpdbopt_sys_info ${HOME}/local/info
tlpdbopt_sys_man ${HOME}/local/man
tlpdbopt_w32_multi_user 0
EOF

# Do the installation unattended.
echo "Installing TeX Live ${tl_release}.  This may take some time."
perl install-tl -profile texlive.profile

texlive_bin_directory=$(find ${HOME}/local/lib/texlive/${tl_release}/bin -maxdepth 2 -name tex -printf "%h\n")

# Description of the TeX Live environment variables
#   - TEXDIR: is the main TeX directory
#   - TEXMFLOCAL: is the directory for site-wide local files
#   - TEXMFSYSVAR: is the directory for variable and automatically generated data
#   - TEXMFSYSCONFIG: is the directory for local configurations
#   - TEXMFVAR: is the directory for personal variable data
#   - TEXMFCONFIG: is the directory for personal configurations
#   - TEXMFHOME: is the directory for user-specific files

cat << EOF > ../set_texlive_envvars.sh
#!/usr/bin/env bash

export TEXDIR=${HOME}/local/lib/texlive/${tl_release}
export TEXMFLOCAL=${HOME}/local/lib/texlive/texmf-local
export TEXMFSYSVAR=${HOME}/local/lib/texlive/${tl_release}/texmf-var
export TEXMFSYSCONFIG=${HOME}/local/lib/texlive/${tl_release}/texmf-config
export TEXMFVAR=${HOME}/.texlive${tl_release}/texmf-var
export TEXMFCONFIG=${HOME}/.texlive${tl_release}/texmf-config
export TEXMFHOME=${HOME}/texmf
export TEXMFDIST=${HOME}/local/lib/texlive/${tl_release}/texmf-dist

export PATH=${texlive_bin_directory}:${PATH}
EOF

# Sourcing the file here only affects subprocesses.
# You'll have to source the file outside of the script process.
. ../set_texlive_envvars.sh

# Requires the variables to have been set above.
cat << EOF >> ${HOME}/.bashrc

export PATH=${PATH}

# TeX Live Environment Variables
# ==============================
export TEXDIR=${TEXDIR}
export TEXMFLOCAL=${TEXMFLOCAL}
export TEXMFSYSVAR=${TEXMFSYSVAR}
export TEXMFSYSCONFIG=${TEXMFSYSCONFIG}
export TEXMFVAR=${TEXMFVAR}
export TEXMFCONFIG=${TEXMFCONFIG}
export TEXMFHOME=${TEXMFHOME}
export TEXMFDIST=${TEXMFDIST}
EOF

# Now get the update manager
echo "Getting the Update Manager Script"
curl -fsSLO http://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh
chmod +x update-tlmgr-latest.sh
mv update-tlmgr-latest.sh ${HOME}/local/bin/update-tlmgr-latest
hash -r
echo "Updating tlmgr"
update-tlmgr-latest &> /dev/null


cd ${start_dir}
echo "Cleaning up"
rm -rf ${HOME}/src/install-tl-20*
rm -f ${HOME}/src/install-tl-unx.tar.gz

echo ""
echo "All done!"
echo -e "You should set the TeX Live environment variables using:\n"
echo -e "  . ~/src/set_texlive_envvars.sh\n"
echo "Otherwise you'll need to log out and log back in (or open a new shell)"
