#!/bin/bash
set -exo pipefail

# Updates
apt-get -y update

# It doesn't make sense to run sudo in Docker's container,
# but some scripts are using it.
apt-get -y install sudo

# Basic utilities
apt-get -y install vim curl wget unzip tmux exuberant-ctags zsh
apt-get -y install python3-pip
apt-get -y install gdb gdb-multiarch
apt-get -y install foremost
apt-get -y install python2.7 python-pip python-dev git libssl-dev libffi-dev
apt-get -y install ipython

# Switch to tools dir for installation
cd $HOME
mkdir -p tools
cd tools

# Install Python tools
pip install --upgrade virtualenv
virtualenv --no-site-package pwn
source pwn/bin/activate
pip install --upgrade pwntools
pip install --upgrade angr
pip install --upgrade r2pipe
deactivate 

# Installing Py2neo for Joerns support
cd $HOME/tools
virtualenv --no-site-package joern
source pwn/bin/activate
wget https://github.com/nigelsmall/py2neo/archive/py2neo-2.0.7.tar.gz
tar zxvf py2neo*
cd py2neo-py2neo-2.0.7
python setup.py install
deactivate

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

# Install 32 bit libs
dpkg --add-architecture i386
apt-get update
apt-get -y install libc6:i386 libncurses5:i386 libstdc++6:i386
apt-get -y install libc6-dev-i386


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

# Personal config
cd $HOME
git clone --recursive https://github.com/huyphan/dotfiles
cd dotfiles
cp .tmux.conf $HOME
cp .vimrc $HOME
cp .zshrc $HOME

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

chsh -s $(which zsh)
