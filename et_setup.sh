#!/bin/bash
set -exo pipefail

# Updates
apt-get -y update

# It doesn't make sense to run sudo in Docker's container,
# but some scripts are using it.
apt-get -y install sudo

# Basic utilities
apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
                   libreadline-dev libsqlite3-dev wget curl llvm \
                   libncurses5-dev xz-utils tk-dev libxml2-dev \
                   libxmlsec1-dev libffi-dev vim curl wget unzip \
                   tmux exuberant-ctags zsh cmake httpie locales \
                   gdb gdb-multiarch foremost \
                   python2.7 python-pip python-dev git \
                   ipython

locale-gen "en_US.UTF-8"
update-locale LC_ALL="en_US.UTF-8"

# Personal config
cd $HOME
git clone --recursive https://github.com/huyphan/dotfiles
cd dotfiles
cp .tmux.conf $HOME
cp .vimrc $HOME
cp .zshrc $HOME

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

# Install 32 bit libs
dpkg --add-architecture i386
apt-get update
apt-get -y install libc6:i386 libncurses5:i386 libstdc++6:i386
apt-get -y install libc6-dev-i386

# Make tools dir for installation
cd $HOME
mkdir -p tools
cd tools

# Install american-fuzzy-lop
# Latest version of AFL (2.52b) only works with clang 4.0
apt-get -y install clang llvm
cd $HOME/tools
wget --quiet http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz
tar -xzvf afl-latest.tgz
rm afl-latest.tgz
wget --quiet http://releases.llvm.org/4.0.0/clang%2bllvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz
tar xvf clang*
cd clang*/bin
export PATH=$PWD:$PATH
cd ../..
(
  cd afl-*
  make
  # build clang-fast
  (
    cd llvm_mode
    make
  )
  make install

  # build qemu-support
  apt-get -y install libtool automake bison libglib2.0-dev libtool-bin
  cd qemu_mode
  ./build_qemu_support.sh
)

# Get clang 6.0 too since it's newer
wget http://releases.llvm.org/6.0.1/clang%2bllvm-6.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
tar xvf "clang+llvm-6.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz"
export PATH=$HOME/tools/clang+llvm-6.0.1-x86_64-linux-gnu-ubuntu-16.04/bin:$PATH

# Install honggfuzz
apt-get -y install binutils-dev libunwind-dev
cd $HOME/tools
git clone https://github.com/google/honggfuzz.git
cd honggfuzz
make

# Installing pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshenv
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshenv
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshenv

# Restart the shell + switch to ZSH to refresh new environment variables
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Use python 2.7 with pyenv
pyenv install 2.7.15
pyenv global 2.7.15

# Install Python tools
pip install --upgrade pwntools
pip install --upgrade angr
pip install --upgrade r2pipe
pip install --upgrade keystone-engine

# Installing Py2neo for Joerns support
cd $HOME/tools
wget https://github.com/nigelsmall/py2neo/archive/py2neo-2.0.7.tar.gz
tar zxvf py2neo*
cd py2neo-py2neo-2.0.7
python setup.py install

# Install joern
apt-get install -y ant openjdk-8-jdk-headless
wget https://github.com/fabsx00/joern/archive/0.3.1.tar.gz
tar xfzv 0.3.1.tar.gz
cd joern-0.3.1
wget http://mlsec.org/joern/lib/lib.tar.gz
tar xfzv lib.tar.gz
ant
alias joern='java -jar $JOERN/bin/joern.jar'

# Install pwndbg
cd $HOME
git clone https://github.com/pwndbg/pwndbg
cd pwndbg
./setup.sh

# Install radare2
cd $HOME
git clone https://github.com/radare/radare2
cd radare2
./sys/install.sh

# Install binwalk
cd $HOME
git clone https://github.com/devttys0/binwalk
cd binwalk
python setup.py install
apt-get install -y squashfs-tools

# Install Firmware-Mod-Kit
apt-get -y install git build-essential zlib1g-dev liblzma-dev python-magic
cd ~/tools
git clone https://github.com/rampageX/firmware-mod-kit.git
cd firmware-mod-kit/src
./configure
make


# Install ROPGadget
git clone https://github.com/JonathanSalwan/ROPgadget
cd ROPgadget
python setup.py install

# Install GO
cd $HOME
wget https://dl.google.com/go/go1.11.linux-amd64.tar.gz
tar zxvf go1.*
mkdir $HOME/.go
export PATH=$HOME/go/bin:$PATH
export GOPATH=$HOME/.go

# Install crashwalk
go get -u github.com/arizvisa/crashwalk
mkdir $HOME/src
cd $HOME/src
git clone https://github.com/jfoote/exploitable

# Install Delve - go debugging
go get github.com/derekparker/delve/cmd/dlv

# Install Rust
cd $HOME
curl -f -L https://static.rust-lang.org/rustup.sh -O
sh rustup.sh
cargo install ripgrep

chsh -s $(which zsh)
