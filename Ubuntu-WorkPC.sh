#!/bin/bash
# Fill these variables before running
OMAKUB_USER_EMAIL=""
OMAKUB_USER_NAME=""

# Disable screen locking and sleep on GNOME before we start. Since we're removing GDM, it gets real cranky if the screen locks before we finish the process.
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
  # Ensure computer doesn't go to sleep or lock while installing
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.desktop.session idle-delay 0
fi

#Change to KDE DE
 sudo apt update -y
 sudo apt install -y kubuntu-desktop 
 sudo apt remove -y ubuntu-desktop gnome-shell && sudo apt autoremove -y

# Populate ~/.local/share/omakub/configs with omakubs default configs and themes...we'll use some of them.
rm -rf ~/.local/share/omakub
git clone https://github.com/basecamp/omakub.git ~/.local/share/omakub >/dev/null

# Install required utils for script
sudo apt install -y curl wget git gpg
sudo apt install -y flatpak
sudo apt install -y kde-config-flatpak plasma-discover-backend-flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install libraries for dev and building packages
sudo apt install -y build-essential pkg-config autoconf bison clang rustc \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 \
  libvips imagemagick libmagickwand-dev mupdf mupdf-tools gir1.2-gtop-2.0 gir1.2-clutter-1.0 \
  redis-tools sqlite3 libsqlite3-0 libmysqlclient-dev libpq-dev postgresql-client postgresql-client-common cargo

# Install mise for managing multiple versions of Ruby, Python, Node.js, and Go. Install Python, Ruby, and Rails.
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1>/dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update -y
sudo apt install -y mise
mise use --global python@latest
mise use --global ruby@latest
mise settings add idiomatic_version_file_enable_tools ruby
mise x ruby -- gem install rails --no-document


# Install Google Chrome and repo for updates
cd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb
xdg-settings set default-web-browser google-chrome.desktop
cd -

# LastPass
wget https://download.cloud.lastpass.com/linux/lplinux.tar.bz2
 tar xjvf lplinux.tar.bz2
 sudo ./install_lastpass.sh

# Signal
wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |
	sudo tee /etc/apt/sources.list.d/signal-xenial.list
rm signal-desktop-keyring.gpg
sudo apt update
sudo apt install -y signal-desktop

cd /tmp
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
rm -f packages.microsoft.gpg
cd -

sudo apt update -y
sudo apt install -y code

mkdir -p ~/.config/Code/User
cp ~/.local/share/omakub/configs/vscode.json ~/.config/Code/User/settings.json

# Install default supported themes
code --install-extension enkia.tokyo-night

# Install terminal apps
# Provides a system clipboard interface for Neovim under Wayland
sudo apt install -y wl-clipboard

# btop is a resource monitor that shows system stats in a terminal UI
sudo apt install -y btop
mkdir -p ~/.config/btop/themes
cp ~/.local/share/omakub/configs/btop.conf ~/.config/btop/btop.conf
cp ~/.local/share/omakub/themes/tokyo-night/btop.theme ~/.config/btop/themes/tokyo-night.theme

# Github CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
	sudo apt update &&
	sudo apt install gh -y

# Set common git aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global pull.rebase true
# Set identification from install inputs
if [[ -n "${OMAKUB_USER_NAME//[[:space:]]/}" ]]; then
  git config --global user.name "$OMAKUB_USER_NAME"
fi

if [[ -n "${OMAKUB_USER_EMAIL//[[:space:]]/}" ]]; then
  git config --global user.email "$OMAKUB_USER_EMAIL"
fi

# Add official docker repo for latest version and install Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y

# Install Docker engine and standard plugins
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
# Give this user privileged Docker access
sudo usermod -aG docker ${USER}
# Limit log size to avoid running out of disk
echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"5"}}' | sudo tee /etc/docker/daemon.json
# Lazy Docker - TUI for managing Docker containers
cd /tmp
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
tar -xf lazydocker.tar.gz lazydocker
sudo install lazydocker /usr/local/bin
rm lazydocker.tar.gz lazydocker
cd -

#LazyGit - TUI for managing Git repositories
cd /tmp
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit.tar.gz lazygit
mkdir -p ~/.config/lazygit/
touch ~/.config/lazygit/config.yml
cd -

#Neovim - Modern text editor
cd /tmp
wget -O nvim.tar.gz "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
tar -xf nvim.tar.gz
sudo install nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
sudo cp -R nvim-linux-x86_64/lib /usr/local/
sudo cp -R nvim-linux-x86_64/share /usr/local/
rm -rf nvim-linux-x86_64 nvim.tar.gz
cd -

# Install luarocks and tree-sitter-cli to resolve lazyvim :checkhealth warnings
sudo apt install -y luarocks tree-sitter-cli

# Only attempt to set configuration if Neovim has never been run
if [ ! -d "$HOME/.config/nvim" ]; then
  # Use LazyVim
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  # Remove the .git folder, so you can add it to your own repo later
  rm -rf ~/.config/nvim/.git
  # Make everything match the terminal transparency
  mkdir -p ~/.config/nvim/plugin/after
  cp ~/.local/share/omakub/configs/neovim/transparency.lua ~/.config/nvim/plugin/after/
  # Default to Tokyo Night theme
  cp ~/.local/share/omakub/themes/tokyo-night/neovim.lua ~/.config/nvim/lua/plugins/theme.lua
  # Turn off animated scrolling
  cp ~/.local/share/omakub/configs/neovim/snacks-animated-scrolling-off.lua ~/.config/nvim/lua/plugins/
  # Turn off relative line numbers
  echo "vim.opt.relativenumber = false" >>~/.config/nvim/lua/config/options.lua
fi

# Other small apps and utils
echo "Installing other small termnial apps and utils"
sudo apt install -y neofetch fzf ripgrep bat eza zoxide plocate apache2-utils fd-find tldr ]
echo "Installing additional apt packages"
sudo apt install -y wireshark haruna
echo "Installing snap apps"
sudo snap install gimp
sudo snap install postman
sudo snap install powershell --classic
sudo snap install kompare
sudo snap install beekeeper-studio
sudo snap install teams-for-linux
sudo snap install aws-cli --classic
sudo snap install onlyoffice-desktopeditors
sudo snap install arduino
sudo snap install remmina
#sudo snap install code --classic  - Do this as an apt package since it adds a PPA and works better as a system app
sudo snap install kcalc
sudo snap install --classic obsidian

# Startship for terminal prompt
sudo curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >>~/.bashrc

# JetBrains IDEs
echo "Installing JetBrains IDEs"
sudo snap install datagrip --classic
sudo snap install pycharm-community --classic
sudo snap install rubymine --classic

# Install necessary packages for KVM virtualization for running Windows VM
sudo apt install -y libvirt0 virt-manager qemu-kvm virtinst bridge-utils
echo "Downloading the VirtIO drivers to ~/Downloads"
mkdir -p ~/Downloads
wget -O ~/Downloads/virtio-win-0.1.240.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.240-1/virtio-win-0.1.240.iso

# Install MS Edge browser for something other than Chrome/FF
echo "Attempting to download and installing Microsoft Edge..."
wget https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_138.0.3351.95-1_amd64.deb?brand=M102
sudo apt install -y ./microsoft-edge-stable_138.0.3351.95-1_amd64.deb?brand=M102

# Setting some preferences
echo "Setting some preferences..."
cat >> ~/.bashrc << 'EOF'

# History settings
HISTCONTROL=ignoreboth
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r"
HISTTIMEFORMAT="%F %T "
HISTSIZE=10000
HISTFILESIZE=20000

alias cat='bat'
alias dig='dog'
alias la='eza -a --icons'
alias ll='eza -alh --icons'
alias lla='eza -la --icons'
alias ls='eza --tree --icons'
alias lt='eza --tree'
alias tree='eza --tree'
alias vim='nvim'
EOF

cat >> ~/.config/starship.toml << 'EOF'
"$schema" = "https://starship.rs/config-schema.json"
format = "[](color_orange)$os$username[](bg:color_yellow fg:color_orange)$directory[](fg:color_yellow bg:color_aqua)$git_branch$git_status[](fg:color_aqua bg:color_blue)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:color_blue bg:color_bg3)$docker_context$conda[](fg:color_bg3 bg:color_bg1)$time[ ](fg:color_bg1)$line_break$character"
palette = "gruvbox_dark"

[c]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = " "

[character]
disabled = false
error_symbol = "[](bold fg:color_red)"
success_symbol = "[](bold fg:color_green)"
vimcmd_replace_one_symbol = "[](bold fg:color_purple)"
vimcmd_replace_symbol = "[](bold fg:color_purple)"
vimcmd_symbol = "[](bold fg:color_green)"
vimcmd_visual_symbol = "[](bold fg:color_yellow)"

[conda]
format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)"
style = "bg:color_bg3"

[directory]
format = "[ $path ]($style)"
style = "fg:color_fg0 bg:color_yellow"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
Developer = "󰲋 "
Documents = "󰈙 "
Downloads = " "
Music = "󰝚 "
Pictures = " "

[docker_context]
format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)"
style = "bg:color_bg3"
symbol = ""

[git_branch]
format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)"
style = "bg:color_aqua"
symbol = ""

[git_status]
format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)"
style = "bg:color_aqua"

[golang]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[haskell]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[java]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = " "

[kotlin]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[line_break]
disabled = false

[nodejs]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[os.symbols]
Alpine = ""
Amazon = ""
Android = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
EndeavourOS = ""
Fedora = "󰣛"
Gentoo = "󰣨"
Linux = "󰌽"
Macos = "󰀵"
Manjaro = ""
Mint = "󰣭"
Raspbian = "󰐿"
RedHatEnterprise = "󱄛"
Redhat = "󱄛"
SUSE = ""
Ubuntu = "󰕈"
Windows = "󰍲"

[palettes.gruvbox_dark]
color_aqua = "#689d6a"
color_bg1 = "#3c3836"
color_bg3 = "#665c54"
color_blue = "#458588"
color_fg0 = "#fbf1c7"
color_green = "#98971a"
color_orange = "#d65d0e"
color_purple = "#b16286"
color_red = "#cc241d"
color_yellow = "#d79921"

[php]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[python]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[rust]
format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)"
style = "bg:color_blue"
symbol = ""

[time]
disabled = false
format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)"
style = "bg:color_bg1"
time_format = "%R"

[username]
format = "[ $user ]($style)"
show_always = true
style_root = "bg:color_orange fg:color_fg0"
style_user = "bg:color_orange fg:color_fg0"
EOF

# Installing system terminal font
echo "Installing system terminal font..."
cd /tmp
wget https://release-assets.githubusercontent.com/github-production-release-asset/27574418/618d36f5-7bcc-4e03-a153-30d18952aa14?sp=r&sv=2018-11-09&sr=b&spr=https&se=2025-07-24T10%3A49%3A17Z&rscd=attachment%3B+filename%3DJetBrainsMono.zip&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2025-07-24T09%3A48%3A55Z&ske=2025-07-24T10%3A49%3A17Z&sks=b&skv=2018-11-09&sig=tWgskAcUYheoIt%2FHtN6lut2oznUxFMsV6BzFZ5VO39c%3D&jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc1MzM1MTI2NSwibmJmIjoxNzUzMzUwOTY1LCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.iWDT6GdkGkiZq7IvsbOOgnrtkibgSzKwOhuxBDwGa48&response-content-disposition=attachment%3B%20filename%3DJetBrainsMono.zip&response-content-type=application%2Foctet-stream
unzip JetBrainsMono.zip
sudo cp /tmp/*.ttf /usr/share/fonts/truetype/
sudo fc-cache -f -v

# Ignition
echo "All Done! Sign in to DL and install Ignition, and reboot into the new system when done."
firefox "https://files.inductiveautomation.com/release/ia/8.1.48/20250429-1106/ignition-8.1.48-linux-64-installer.run"