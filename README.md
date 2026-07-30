# Use your MIDI Controller to control Note Block Studio!

This repository contains Linux scripts designed to connect any USB MIDI device to Minecraft Note Block Studio. This works by reading MIDI messages sent to your computer, and outputting keyboard shortcuts for actions that would otherwise be inaccessible. Note that this repository is intended for distros with the KDE Plasma desktop; however, with minor modifications it can be used in other environments. I also have only tested this on Fedora and CachyOS (Arch-based), but it should work on any distro that supports the dependencies.


## Setup

Please *make sure* you understand what each command does before running it. You should never run commands from the internet without knowing what they do. I'm not responsible if you accidentally mess up your system!


### 1. Install dependencies

First, install the dependency packages kdotool and ydotool, using the preferred method for your distro. Because of Wayland, ydotool requires a daemon running in the background to work properly. The following steps detail how to set this up properly.


### 2. Create a secure udev rule

Many guides suggest adding your user to the `input` group, but this is a security risk as it grants read access to all keyboards (allowing keylogging). Instead, use a `uaccess` tag, which dynamically grants access only to the physically logged-in user.

Create a new udev rule file:
```bash
sudo nano /etc/udev/rules.d/80-uinput.rules
```

Paste the following line into the file:
```text
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
```
Save and exit the file.


### 3. Reload udev rules

Apply the new rule without needing to reboot:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```


### 4. Start the daemon as a user service

Instead of running the system-wide root daemon, start `ydotoold` as a user-level systemd service. This ensures the daemon runs with your user's permissions and creates a socket you own.

First, disable and stop the root service if it's currently running:
```bash
sudo systemctl disable --now ydotoold
```

Next, enable and start the user-level service:
```bash
systemctl --user enable --now ydotoold
```
*If you receive an error running this command, you may need to add a `ydotoold.service` file manually before enabling. See below for more details.*


### 5. Point ydotool to your user socket

Because you are running a user daemon, the communication socket is now located in your user's runtime directory instead of the system's `/tmp` folder. You need to tell the `ydotool` command where to find it.

Add this environment variable to your shell's configuration file (e.g., `~/.bashrc` or `~/.zshrc`):
```bash
export YDOTOOL_SOCKET="$XDG_RUNTIME_DIR/ydotool.sock"
```

Reload your shell configuration (or log out and log back in), for example:
```bash
source ~/.bashrc
```

*Note on GUI launchers: With many popular shells, GUI launchers like KRunner inherit your environment variables perfectly. However, if you notice `ydotool` commands aren't working when the script is launched from a GUI, you may need to add the `export YDOTOOL_SOCKET` line directly to the top of your `launcher.sh` script to ensure it is sourced*


### 6. Setup a folder for Note Block Studio and launch assets

I like to organize my applications in a folder in my home directory:
```bash
mkdir -p Applications/Minecraft.Note.Block.Studio
cd Applications/Minecraft.Note.Block.Studio
```

Next, put the [Note Block Studio .appimage](https://github.com/OpenNBS/NoteBlockStudio/releases) into the newly-created app folder, and rename it something like `Minecraft.Note.Block.Studio.appimage`. Also, if you want the desktop shortcut to look nice, I'd recommend grabbing an [app icon](https://avatars.githubusercontent.com/u/95711495?s=200&v=4).

By default, files on Linux aren't executable. To make NBS executable, run this command:
```bash
chmod +x Minecraft.Note.Block.Studio.appimage # If you named the file something else, use that instead
```

Next, either clone the repository or download the .zip and extract the contents to this folder.

Finally, rename `template-launcher.sh` to `launcher.sh`.


### 7. Customize your script

`launcher.sh` is the file where you will connect your physical MIDI controls to digital actions. To begin customization, pull it up in your favorite code editor. As for what you can do, the sky's the limit!

Take a peek at `example-launcher.sh` for ideas! To figure out what events certain MIDI Controller buttons output, use the following steps:
```bash
# Figure out what MIDI port your keyboard is on
aseqdump -l

# Start listening for MIDI events on your keyboard's port (replace xx:x with the port)
aseqdump -p xx:x
```

When done making changes, save your script, and then make it executable:
```bash
chmod +x launcher.sh
```


### 8. Create a KDE desktop entry

In order for KDE to register your app in menus, we need to create a custom .desktop entry:
```bash
nano ~/.local/share/applications/Minecraft.Note.Block.Studio.desktop
```

Here's a template for what to put in the new .desktop file (make sure to **change YOUR_USERNAME** to your actual username!):
```ini
[Desktop Entry]
Type=Application
Name=Minecraft Note Block Studio
Comment=Create songs using note blocks
Exec=/home/YOUR_USERNAME/Applications/Minecraft.Note.Block.Studio/launcher.sh # Replace with the actual path if different from in this guide
Icon=/home/YOUR_USERNAME/Applications/Minecraft.Note.Block.Studio/icon.png # Also replace (or remove this line if you aren't using a custom icon)
Terminal=false
Categories=AudioVideo;Audio;
```

Now, save and exit (`ctrl+o` then `ctrl+x` for nano). *If the app doesn't show up in the application launcher right away, you can force KDE to rebuild its application cache by running `kbuildsycoca6` (or `kbuildsycoca5` if you're on an older version of Plasma).*


### 9. Launch the app!

Using your preferred method (I like KRunner), launch the newly-created NBS desktop entry. The application should load while also running your script in the background, allowing for shortcut detection. I would also recommend adding your MIDI keyboard as a MIDI device in NBS, so that the normal keys work too.


## Troubleshooting

If you encountered an error with enabling ydotoold, you'll want to manually add this config file to `~/.config/systemd/user` with the name `ydotoold.service`:
```ini
[Unit]
Description=ydotoold Backend daemon for ydotool
After=default.target

[Service]
Type=simple
ExecStart=/usr/bin/ydotoold --socket-path=%t/ydotool.sock
Restart=on-failure

[Install]
WantedBy=default.target
```

Then, try to enable it again:
```bash
systemctl --user enable --now ydotoold
```


## Contributing

Pull requests and suggestions are welcome! If you find a bug, have an idea for a better tech stack, or figure out a seamless adaptation for another desktop environment, feel free to open an issue or submit a PR.


## Credits

This setup wouldn't be possible without these fantastic open-source projects:
*   [OpenNBS](https://github.com/OpenNBS/NoteBlockStudio) - The community-driven continuation of Minecraft Note Block Studio.
*   [ydotool](https://github.com/ReimuNotMoe/ydotool) - Generic command-line automation and keystroke simulation on Wayland.
*   [kdotool](https://github.com/jinliu/kdotool) - xdotool-like window manipulation on KDE Plasma Wayland.