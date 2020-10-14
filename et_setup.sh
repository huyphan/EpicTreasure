#!/bin/bash
set -exo pipefail

# Updates
apt-get -y update

# It doesn't make sense to run sudo in Docker's container,
# but some scripts are using it.
apt-get -y install sudo

# Basic utilities
DEBIAN_FRONTEND="noninteractive" apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
                   libreadline-dev libsqlite3-dev wget curl llvm \
                   libncurses5-dev xz-utils tk-dev libxml2-dev \
                   libxmlsec1-dev libffi-dev vim curl wget unzip \
                   tmux exuberant-ctags zsh cmake httpie locales \
                   gdb gdb-multiarch foremost \
                   python3 python3-pip python3-dev python3-setuptools git 

locale-gen "en_US.UTF-8"
update-locale LC_ALL="en_US.UTF-8"

# Personal config
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

cd $HOME
git clone --recursive https://github.com/huyphan/dotfiles
cd dotfiles
cp .tmux.conf $HOME
cp .vimrc $HOME
cp .zshrc $HOME
cp .p10k.zsh $HOME

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
wget --quiet https://github.com/google/AFL/archive/v2.57b.tar.gz
tar -xzvf v2.57b.tar.gz
rm v2.57b.tar.gz
# wget --quiet http://releases.llvm.org/4.0.0/clang%2bllvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz
# tar xvf clang*
# cd clang*/bin
# export PATH=$PWD:$PATH
# cd ../..
(
  cd AFL-*
  make
  # build clang-fast
  (
    cd llvm_mode
    make
  )
  make install

  # build qemu-support
  # apt-get -y install libtool automake bison libglib2.0-dev libtool-bin
  # cd qemu_mode
  # ./build_qemu_support.sh
)

# Get clang 6.0 too since it's newer
# wget http://releases.llvm.org/6.0.1/clang%2bllvm-6.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
# tar xvf "clang+llvm-6.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz"
# export PATH=$HOME/tools/clang+llvm-6.0.1-x86_64-linux-gnu-ubuntu-16.04/bin:$PATH

# Install honggfuzz
apt-get -y install binutils-dev libunwind-dev
cd $HOME/tools
git clone https://github.com/google/honggfuzz.git
cd honggfuzz
make

# Install Python tools
pip3 install --upgrade pwntools
pip3 install --upgrade angr
pip3 install --upgrade r2pipe
pip3 install --upgrade keystone-engine
pip3 install --upgrade qiling
pip3 install --upgrade ipython
pip3 install --upgrade monkeyhex

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
python3 setup.py install
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
python3 setup.py install

# Install GO
cd $HOME
wget https://golang.org/dl/go1.15.2.linux-amd64.tar.gz
tar zxvf go1.*
mkdir $HOME/.go
export PATH=$HOME/go/bin:$PATH
export GOPATH=$HOME/.go
rm go1.15.2.linux-amd64.tar.gz


# Install crashwalk
go get -u github.com/arizvisa/crashwalk
mkdir $HOME/src
cd $HOME/src
git clone https://github.com/jfoote/exploitable

# Install Delve - go debugging
go get github.com/derekparker/delve/cmd/dlv

# Install Rust
cd $HOME
apt-get -y install rustc
cargo install ripgrep

chsh -s $(which zsh)
