#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor;
use File::Copy;

# Set up some defaults
my $username = 'me';
my $shell = '/usr/bin/bash';

my @windows_tools = qw{
https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/refs/heads/master/Rubeus.exe
https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/refs/heads/master/Seatbelt.exe
https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/refs/heads/master/SharpUp.exe
https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/refs/heads/master/Certify.exe
https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/refs/heads/master/SharpChrome.exe
https://github.com/peass-ng/PEASS-ng/releases/download/20251017-d864f4c3/winPEAS.bat
https://github.com/peass-ng/PEASS-ng/releases/download/20251017-d864f4c3/winPEASx64.exe
https://github.com/peass-ng/PEASS-ng/raw/refs/heads/master/winPEAS/winPEASps1/winPEAS.ps1
https://github.com/nicocha30/ligolo-ng/releases/download/v0.8.2/ligolo-ng_agent_0.8.2_windows_amd64.zip
https://github.com/nicocha30/ligolo-ng/releases/download/v0.8.2/ligolo-ng_proxy_0.8.2_windows_amd64.zip
https://github.com/Kevin-Robertson/Inveigh/raw/refs/heads/master/Inveigh.ps1
https://github.com/SnaffCon/Snaffler/releases/download/1.0.224/Snaffler.exe
https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.7/LaZagne.exe

};

my @linux_tools = qw{
https://github.com/peass-ng/PEASS-ng/releases/download/20251017-d864f4c3/linpeas.sh
https://github.com/peass-ng/PEASS-ng/releases/download/20251017-d864f4c3/linpeas_linux_amd64
https://github.com/nicocha30/ligolo-ng/releases/download/v0.8.2/ligolo-ng_agent_0.8.2_linux_amd64.tar.gz
https://github.com/nicocha30/ligolo-ng/releases/download/v0.8.2/ligolo-ng_proxy_0.8.2_linux_amd64.tar.gz
https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64

};

sub printlog {
    my ( $message ) = @_;
    print color ('bold yellow');
    print "Building a kali machine worthy of Mordor: ";
    print color ('bold red');
    print "$message...\n";
    print color ('reset');

}

my $homedir = "/home/$username";
chdir $homedir or die "Unable to chdr to $homedir";

my $passwd_entry = `getent passwd $username`;
if ( $passwd_entry !~ $shell ) {
    printlog "Changing shell to $shell";
    system "chsh $username -s $shell";
} else { &printlog("Skipping changing shell; it\'s already set to $shell"); }

&printlog("Upgrading system");
system "sudo apt -y update && sudo apt -y full-upgrade";

&printlog("Installing software");
system "sudo apt -y install perl-doc neovim sliver bloodhound gdb keepass2 libreoffice jq";

&printlog("Removing unneeded software");
system "sudo apt -y autoremove";

my $private_key = "/home/$username/.ssh/id_ed25519";
if ( ! -f $private_key ) {
    &printlog("Generating SSH keys");
    system "ssh-keygen -f $private_key -N ''";
} else { &printlog("Skipping generating SSH keys; they already exist in $private_key"); }

&printlog("Creating directory structure");
my @directory_list = qw( artifacts transfer transfer/tools transfer/tools/linux transfer/tools/windows transfer/shells transfer/exploits tmux-logs);
foreach my $directory (@directory_list) {
    my $absolute_directory = "${homedir}/${directory}";
    if ( ! -d $absolute_directory ) {
        mkdir $absolute_directory, 0700 or die "Unable to create directory $absolute_directory";
    }
}

&printlog("Downloading tools");
my $windows_directory = "${homedir}/transfer/tools/windows";
my $linux_directory = "${homedir}/transfer/tools/linux";

chdir $windows_directory or die "Unable to change directory to $windows_directory";
foreach my $tool ( @windows_tools ) {
    print "Downloading $tool\n";
    system "wget -nc -q $tool";
}

chdir $linux_directory or die "Unable to change directory to $linux_directory";
foreach my $tool ( @linux_tools ) {
    print "Downloading $tool\n";
    system "wget -nc -q $tool";
}

&printlog("Creating symlinks to additional tools");
system "ln -s /usr/share/windows-resources $windows_directory/kali-windows-resources";
system "ln -s /usr/share/windows-binaries $windows_directory/kali-windows-binaries";

&printlog("Cloning git repositories");
my $gitdir = "$homedir" . "/git";
if ( ! -d "$gitdir" ) {
    mkdir $gitdir, 0700 or die "Unable to create $gitdir";
}
chdir $gitdir or die "Unable to chdir to $gitdir";
# placeholder... no git repos to clone yet
chdir $homedir or die "Unable to chdr to $homedir";

&printlog("Customizing ~/.bashrc");
my $git_bashrc_file = "${homedir}/git/build-me-a-kali/files/bashrc";
my $bashrc_file = "${homedir}/.bashrc";
if ( -f $bashrc_file ) {
    print "renaming $bashrc_file to ${bashrc_file}.orig\n";
    rename $bashrc_file, "${bashrc_file}.orig" or 
        die "unable to back up $bashrc_file";
}
if ( -f $git_bashrc_file ) {
    copy($git_bashrc_file, $bashrc_file) or
        die "unable to copy $git_bashrc_file to $bashrc_file";
}

&printlog("Customizing ~/.vimrc");
my $git_vimrc_file = "${homedir}/git/build-me-a-kali/files/vimrc";
my $vimrc = "${homedir}/.vimrc";
if ( -f $vimrc ) {
    print "renaming $vimrc to ${vimrc}.orig\n";
    rename $vimrc, "${vimrc}.orig" or 
        die "unable to back up $vimrc";
}
if ( -f $git_bashrc_file ) {
    copy($git_vimrc_file, $vimrc) or 
        die "unable to copy $git_vimrc_file to $vimrc";
}

&printlog("Customizing ~/.tmux.conf");
my $git_tmux_conf = "${homedir}/git/build-me-a-kali/files/tmux.conf";
my $tmux_conf = "${homedir}/.tmux.conf";
my $git_logging_script = "${homedir}/git/build-me-a-kali/files/ensure_tmux_logging_on.sh";
my $logging_script = "${homedir}/.ensure_tmux_logging_on.sh";
if ( -f $tmux_conf ) {
    print "renaming $tmux_conf to ${tmux_conf}.orig\n";
    rename $tmux_conf, "${tmux_conf}.orig" or 
        die "unable to back up $tmux_conf";
}
if ( -f $git_tmux_conf ) {
    copy($git_tmux_conf, $tmux_conf) or 
        die "unable to copy $git_tmux_conf to $tmux_conf";
}
copy($git_logging_script, $logging_script) or die "unable to copy $git_logging_script to $logging_script";
chmod 0700, $logging_script;
system "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm";


&printlog("Postinstallation instructions");
print color ("bold green");
print "1. Copy the following SSH key to github:\n";
print color ("reset");
system "cat ${private_key}.pub";
print color ("bold green");
print "2. Then run the following commands:\n";
print color ("reset");
print 'cd ~/git' . "\n";
print 'git clone git@github.com:nemorin0/notes.git' . "\n";
print 'git clone git@github.com:nemorin0/htb.git' . "\n";
print color ("bold green");
print "3. In tmux, run CTRL-B I to set up tmux plugins and logging\n";
print "4. Don't forget to copy over your bash history, which might come in handy!\n";
print "5. Reboot.\n";
print "6. Happy hacking!\n";
print color ("reset");

# To do:
# * nvim/mousetrap install
# * firefox bookmarks
# * sample pictures (preferably cobra themed)
# * desktop backgrounds?
# * install fonts?
