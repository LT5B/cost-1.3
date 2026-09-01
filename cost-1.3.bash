#!/bin/bash

echo "Installing a related department..."
curl -s -L -R -O https://www.kernel.org/pub/software/scm/git/git-2.55.0.tar.gz
tar zxf git-2.55.0.tar.gz
cd git-2.55.0
sudo ./configure

echo "Creating Cost directory structure..."
sudo mkdir -p /opt/cost/{bin,flag,ruby,doc,update,include,frameworks,lib,libexec,share,etc,manpages}
sudo mkdir -p /opt/cost/library/{cost,install-type,archive}
sudo mkdir -p /private/cost/packages

echo "Creating configuration files..."

# --- Main Wrapper Command ---
sudo tee "/opt/cost/bin/cost" > /dev/null << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: cost <flag> [package]"
    exit 1
fi

if [ ! -f "/opt/cost/flag/$1" ]; then
    echo "Cost: Command not found: cost $1"
    exit 1
else
    bash "/opt/cost/flag/$1" "${@:2}"
fi
EOF
sudo chmod +x "/opt/cost/bin/cost"

# --- Install Command ---
sudo tee "/opt/cost/flag/install" > /dev/null << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: cost install <package>"
    exit 1
fi

# Note the path contains a dot prefix (.$1)
if [ ! -d "/private/cost/packages/.$1" ]; then
    echo "Cost: Package not found: $1"
    exit 1
else
    echo "Copying packages folder..."
    sudo cp -r "/private/cost/packages/.$1" "/opt/cost/library/archive/$1"
    sudo cp -r "/opt/cost/library/archive/$1" "/opt/cost/$1"
    echo "Checking..."
    cd "/opt/cost/$1" || exit

    if [ -f "Makefile" ]; then
        echo "Running installer (make)..."
        sudo make install
    elif [ -f "Configure" ]; then
        echo "Running installer (Configure)..."
        sudo ./Configure
    elif [ -f "install.sh" ]; then
        echo "Running installer (install.sh)..."
        sudo bash ./install.sh
    elif [ -f "install.bash" ]; then
        echo "Running installer (install.bash)..."
        sudo bash ./install.bash
    elif [ -f "install.zsh" ]; then
        echo "Running installer (install.zsh)..."
        sudo zsh ./install.zsh
    elif [ -f "install.rb" ]; then
        echo "Running installer (install.rb)..."
        sudo ruby install.rb
    else
        echo "Cost: This package does not have an installer file: $1"
        sudo rm -rf "/opt/cost/$1"
        sudo rm -rf "/opt/cost/library/archive/$1"
        exit 1
    fi

    sudo rm -rf "/opt/cost/$1"
    
    # Update PATH for the current user executing sudo (if any)
    USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
    echo "export PATH=\"\$PATH:/opt/cost/bin/$1\"" | sudo tee -a "$USER_HOME/.bashrc" > /dev/null
    echo "export PATH=\"\$PATH:/opt/cost/bin/$1\"" | sudo tee -a "$USER_HOME/.zshrc" > /dev/null

    if [ -f "/opt/cost/include/$1.h" ]; then
        echo "export PATH=\"\$PATH:/opt/cost/include/$1.h\"" | sudo tee -a "$USER_HOME/.bashrc" > /dev/null
        echo "export PATH=\"\$PATH:/opt/cost/include/$1.h\"" | sudo tee -a "$USER_HOME/.zshrc" > /dev/null
    fi

    if [ -d "/opt/cost/frameworks/$1.framework" ]; then
        echo "export PATH=\"\$PATH:/opt/cost/frameworks/$1.framework\"" | sudo tee -a "$USER_HOME/.bashrc" > /dev/null
    fi
fi
EOF

# --- Uninstall Command ---
sudo tee "/opt/cost/flag/uninstall" > /dev/null << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: cost uninstall <package>"
    exit 1
fi

if [ ! -d "/opt/cost/library/archive/$1" ]; then
    echo "Cost: Package not found: $1"
    exit 1
else
    sudo rm -rf "/opt/cost/library/archive/$1"
    sudo rm -rf "/opt/cost/bin/$1"
    [ -f "/opt/cost/include/$1.h" ] && sudo rm "/opt/cost/include/$1.h"
    [ -f "/opt/cost/lib/$1.dylib" ] && sudo rm "/opt/cost/lib/$1.dylib"
    [ -d "/opt/cost/lib/$1" ] && sudo rm -rf "/opt/cost/lib/$1"
    [ -d "/opt/cost/frameworks/$1.framework" ] && sudo rm -rf "/opt/cost/frameworks/$1.framework"
    [ -f "/opt/cost/manpages/$1.1" ] && sudo rm "/opt/cost/manpages/$1.1"
    echo "Cost: Successfully uninstalled $1"
fi
EOF

# --- Information Commands ---
echo -e '#!/bin/bash\ncat "/opt/cost/doc/license.md"' | sudo tee "/opt/cost/flag/license" > /dev/null
echo -e '#!/bin/bash\ncat "/opt/cost/doc/readme.md"' | sudo tee "/opt/cost/flag/readme" > /dev/null
echo -e '#!/bin/bash\ncat "/opt/cost/doc/version.md"' | sudo tee "/opt/cost/flag/version" > /dev/null
echo -e '#!/bin/bash\ncat "/opt/cost/doc/help.md"' | sudo tee "/opt/cost/flag/help" > /dev/null
echo -e '#!/bin/bash\ncat "/opt/cost/doc/package-owner.md"' | sudo tee "/opt/cost/flag/package-owner" > /dev/null
echo -e '#!/bin/bash\ncat "/opt/cost/doc/owner-email.md"' | sudo tee "/opt/cost/flag/owner-email" > /dev/null
echo -e '#!/bin/bash\ncat "/opt/cost/doc/copyright.md"' | sudo tee "/opt/cost/flag/copyright" > /dev/null

# --- Set-Version Command ---
sudo tee "/opt/cost/flag/set-version" > /dev/null << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: cost set-version <version>"
    exit 1
fi
git clone -q "https://github.com/LT5B/cost-$1" "$HOME/cost-$1"
sudo rm -rf "/opt/cost"
cd "$HOME/cost-$1" || exit
sudo ./install.sh
EOF

# --- Search Command ---
sudo tee "/opt/cost/flag/search" > /dev/null << 'EOF'
#!/bin/bash
echo "Available packages in Cost:"
# Search for directories (dot prefix removed for display)
find "/private/cost/packages" -mindepth 1 -maxdepth 1 | perl -MList::Util=shuffle -e 'print shuffle <STDIN>' | head -n 10 | while read -r file; do
    base_name=$(basename "$file")
    clean_base="${base_name#.}" # Remove the leading dot
    echo "- $clean_base"
done
EOF

# --- Create Command ---
sudo tee "/opt/cost/flag/create" > /dev/null << 'EOF'
#!/bin/bash
sudo ruby "/opt/cost/ruby/create.rb"
EOF

# --- Documentation (Docs) ---
sudo tee "/opt/cost/doc/license.md" > /dev/null << 'EOF'
# COST LICENSE
Copyright (c) 2026 LT5B

## 1. Permission
Permission is hereby granted, free of charge, to any person obtaining a copy of the `cost` Bash package and associated files (the "Software"), to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the conditions stated in this License.

## 2. Conditions
The following conditions apply:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* Modified versions of the Software must clearly indicate that changes have been made.
* The name "LT5B" shall not be used to endorse or promote products derived from the Software without prior written permission.

## 3. Disclaimer
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

IN NO EVENT SHALL LT5B BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## 4. Attribution
When the Software is redistributed or included in another project, reasonable attribution to **LT5B** and the `cost` Bash package is appreciated.

## 5. License Version
This license is the **COST License, Version 1.0**, created for the `cost` Bash package by **LT5B**.

Copyright (c) 2026 LT5B. All rights reserved.
EOF

sudo tee "/opt/cost/doc/readme.md" > /dev/null << 'EOF'
# Cost

Cost is a Bash-based package management script designed to provide a simple and lightweight way to manage software packages directly from the command line.

Created by LT5B.

## Features
* Simple package management
* Lightweight Bash implementation
* Command-line interface
* Search for available packages
* Install packages
* Remove packages
* Update packages
* View package information
* Designed to be easy to extend
* Built for Unix-like environments

## Philosophy
Cost is designed around three principles:
1. **Simplicity:** Package management should not require complicated commands.
2. **Lightweight Design:** Cost is implemented as a Bash script, keeping the project small and easy to inspect.
3. **Ease of Use:** Commands should be understandable and predictable for users.

## Requirements
Cost requires:
* Bash
* A Unix-like operating system
* Standard command-line utilities

## Version
Current Project: Cost
Language: Bash
Creator: LT5B

## Author
LT5B

Cost is an independent Bash project created to make package management more accessible through a simple command-line experience.

Cost — Simple package management, powered by Bash.
EOF

echo "engeleditorfpe@gmail.com" | sudo tee "/opt/cost/doc/owner-email.md" > /dev/null
echo "LT5B" | sudo tee "/opt/cost/doc/package-owner.md" > /dev/null
echo "Cost 1.3" | sudo tee "/opt/cost/doc/version.md" > /dev/null
echo -e "Copyright (C) 2026 LT5B - COST\n[*] No copy\n[*] No reupload" | sudo tee "/opt/cost/doc/copyright.md" > /dev/null
echo "Cost Install Type Directory" | sudo tee "/opt/cost/library/install-type/directory" > /dev/null

# --- Ruby Scripts ---
sudo tee "/opt/cost/ruby/create.rb" > /dev/null << 'EOF'
#!/usr/bin/env ruby
require 'fileutils'

print "Enter the source directory path: "
source_dir = gets.chomp.strip

print "Enter the name of package: " 
package_name = gets.chomp.strip

unless Dir.exist?(source_dir)
  puts "Error: Source directory does not exist!"
  exit 1
end

if package_name.empty?
  puts "Error: Package name cannot be empty!"
  exit 1
end

target_base = "/private/cost/packages"
FileUtils.mkdir_p(target_base) unless Dir.exist?(target_base)

# Create target path with dot prefix
target_path = File.join(target_base, ".#{package_name}")

# Remove old package if it exists
FileUtils.rm_rf(target_path) if File.exist?(target_path)

begin
  FileUtils.cp_r(source_dir, target_path)
  puts "Created hidden package directory: #{target_path} (from #{source_dir})"
rescue => e
  puts "Failed to create package #{package_name}: #{e.message}"
end
puts "Configuration completed successfully!"
EOF

sudo tee "/opt/cost/ruby/copyer.rb" > /dev/null << 'EOF'
#!/usr/bin/env ruby
require 'fileutils'
require 'etc'

source_user = nil
Etc.passwd do |user|
  if Dir.exist?("/opt/cost") && user.uid >= 1000
    source_user = user.name
    break
  end
end

if source_user.nil?
  puts "Error: No user found with the /opt/cost directory."
  exit
end

source_path = "/private/cost/packages"
Etc.passwd do |user|
  next if user.name == source_user || user.uid < 1000
  target_path = "/private/cost/packages" 
  begin
    FileUtils.mkdir_p(target_path)
    FileUtils.cp_r("#{source_path}/.", target_path)
    FileUtils.chown_R(user.name, nil, target_path)
  rescue => e
    puts "-> Failed to copy for #{user.name}: #{e.message}"
  end
end
EOF

# Run Ruby Copyer
sudo ruby "/opt/cost/ruby/copyer.rb"

# Update PATH for the user executing sudo
USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
echo 'export PATH="$PATH:/opt/cost/bin"' | sudo tee -a "$USER_HOME/.bashrc" > /dev/null
echo 'export PATH="$PATH:/opt/cost/bin"' | sudo tee -a "$USER_HOME/.zshrc" > /dev/null

sudo cp "/opt/cost/bin/cost" "/opt/cost/library/cost/cost-1.3"

# Source the profiles (will only affect current shell execution environment)
[ -f "$USER_HOME/.bashrc" ] && source "$USER_HOME/.bashrc"
[ -f "$USER_HOME/.zshrc" ] && source "$USER_HOME/.zshrc"

echo "Cost installation completed!"
