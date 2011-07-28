#!/bin/bash
# Mon script de post installation desktop Debian 6.0
#
# Nicolargo - 07/2011
# GPL
#
# Syntaxe: # su - -c "./debian6postinstall.sh"
# Syntaxe: or # sudo ./debian6postinstall.sh

VERSION="1.57"

#=============================================================================
# Liste des applications installés par le script
# A adapter à vos besoins...
#-----------------------------------------------------------------------------

# Fichier sources.list de référence
SOURCES_LIST="https://raw.github.com/nicolargo/debianpostinstall/master/sources.list-debian6desktop"

# Ajouter la liste de vos logiciels séparés par des espaces
LISTE=""

# Theme GTK: Equinox +
LISTE=$LISTE" conky-all"
EQUINOX_ENGINE_VERSION="1.50"
EQUINOX_THEME_VERSION="1.50"
FAENZA_VERSION="0.9.2"

# Gnome-Do
LISTE=$LISTE" gnome-do gnome-do-plugins"

# GStreamer: la totale
LISTE=$LISTE" "`apt-cache search gstreamer | awk '{ print $1 }' | grep ^gstreamer | xargs -eol`

# Terminator
LISTE=$LISTE" terminator"

# Chromium Web Browser
LISTE=$LISTE" chromium-browser chromium-browser-l10n flashplugin-nonfree"

# Hotot
LISTE=$LISTE" hotot"

# Filezilla: le client FTP ultime
LISTE=$LISTE" filezilla"

# Spotify
LISTE=$LISTE" spotify-client-qt spotify-client-gnome-support"

# Dropbox (pre-requis)
LISTE=$LISTE" libnautilus-extension-dev libnotify-dev python-docutils"
DROPBOX_VERSION="0.6.7"

# Multimedia: Vlc + ffmpeg
LISTE=$LISTE" vlc ffmpeg"

# Shutter: Capture d'image
LISTE=$LISTE" shutter libgoo-canvas-perl"

# OpenVPN (je l'utilise pour monter mon VPNTunnel)
LISTE=$LISTE" openvpn resolvconf network-manager-openvpn-gnome"

# Dev
LISTE=$LISTE" subversion git anjuta python-rope"
TEXTADEPT_VERSION="3.9"

#=============================================================================

# Variables globales
#-------------------

HOME_PATH=`grep $USERNAME /etc/passwd | cut -d: -f6`
APT_GET="apt-get -q -y --force-yes"
WGET="wget --no-check-certificate"
DATE=`date +"%Y%m%d%H%M%S"`
LOG_FILE="/tmp/debian6postinstall-$DATE.log"

# Fonctions utilisées par le script
#---------------------------------

displaymessage() {
  echo "$*"
}

displaytitle() {
  displaymessage "------------------------------------------------------------------------------"
  displaymessage "$*"
  displaymessage "------------------------------------------------------------------------------"

}

displayerror() {
  displaymessage "$*" >&2
}

# Premier parametre: ERROR CODE
# Second parametre: MESSAGE
displayerrorandexit() {
  local exitcode=$1
  shift
  displayerror "$*"
  exit $exitcode
}

# Premier parametre: MESSAGE
# Autres parametres: COMMAND
displayandexec() {
  local message=$1
  echo -n "[En cours] $message"
  shift
  echo ">>> $*" >> $LOG_FILE 2>&1
  sh -c "$*" >> $LOG_FILE 2>&1
  local ret=$?
  if [ $ret -ne 0 ]; then
    echo -e "\r\e[0;31m   [ERROR]\e[0m $message"
  else
    echo -e "\r\e[0;32m      [OK]\e[0m $message"
  fi
  return $ret
}

# Debut du programme
#-------------------

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  displayerror 1 "Le script doit être lancé en root: # su - -c $0"
fi

# Création du fichier de log
echo "Debut du script" > $LOG_FILE

# Telechargement du fichier sources.list
# Generated by: http://debgen.simplylinux.ch/
# Source: https://raw.github.com/nicolargo/debianpostinstall/master/sources.list-debian6desktop
#----------------------------------------------------------------------------------------------
displaytitle "-- Téléchargement du fichier sources.list
-- $SOURCES_LIST"
displayandexec "Archivage du fichier sources.list actuel" cp /etc/apt/sources.list /etc/apt/sources.list-BACKUP
displayandexec "Téléchargement du nouveau fichier sources.list" $WGET -O /etc/apt/sources.list $SOURCES_LIST

# Erreur Dynamic MMap ran out of room
echo 'APT::Cache-Limit "12500000";' >> /etc/apt/apt.conf

# Installation des cles
#----------------------

displaytitle "-- Installation des clés nécessaires au sources.list"

# Dotdeb
displayandexec "Installation clés du dépôt Dotdeb" "$WGET -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -"
# Google
displayandexec "Installation clés du dépôt Google" "$WGET -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -"
# Skype
displayandexec "Installation clés du dépôt Skype" "gpg --keyserver pgp.mit.edu --recv-keys 0xd66b746e && gpg --export --armor 0xd66b746e | apt-key add -"
# Virtualbox
displayandexec "Installation clés du dépôt VirtualBox" "$WGET http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -"
# Hotot
displayandexec "Installation clés du dépôt Hotot" "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 41011AE2"
# Spotify
displayandexec "Installation clés du dépôt Spotify" "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4E9CFF4E"
# Chromium (Ubuntu PPA)
displayandexec "Installation clés du dépôt Chromium" "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4E5E17B5"
# Debian multimedia
displayandexec "Installation clés du dépôt Debian Multimedia" "$APT_GET update && $APT_GET install debian-multimedia-keyring"

# Mise a jour des depots
#-----------------------

displaytitle "-- Mise à jour du système"

displayandexec "Mise à jour de la liste des dépots" $APT_GET update
displayandexec "Mise à jour des logiciels" $APT_GET upgrade

# Installation des logiciels
#---------------------------

displaytitle "-- Installation des logiciels suivants: $LISTE"

displayandexec "Installation des logiciels" $APT_GET install $LISTE


# Compile Dropbox depuis les sources
#-----------------------------------

displaytitle "-- Compilation de Dropbox depuis les sources"

displayandexec "Téléchargement de Dropbox v$DROPBOX_VERSION" $WGET -O nautilus-dropbox-$DROPBOX_VERSION.tar.bz2 http://www.dropbox.com/download?dl=packages/nautilus-dropbox-$DROPBOX_VERSION.tar.bz2
displayandexec "Décompression de Dropbox v$DROPBOX_VERSION" "bzip2 -d nautilus-dropbox-$DROPBOX_VERSION.tar.bz2 ; tar xvf nautilus-dropbox-$DROPBOX_VERSION.tar"
cd nautilus-dropbox-$DROPBOX_VERSION
displayandexec "Configuration de Dropbox v$DROPBOX_VERSION" ./configure
displayandexec "Compilation de Dropbox v$DROPBOX_VERSION" make
displayandexec "Installation de Dropbox v$DROPBOX_VERSION" make install
cd -
rm -rf nautilus-dropbox-$DROPBOX_VERSION nautilus-dropbox-$DROPBOX_VERSION.tar

# Custom du systeme
#------------------

displaytitle "-- Customisation du système"

# GTK Theme
displayandexec "Téléchargement Equinox Engine v$EQUINOX_ENGINE_VERSION" $WGET http://gnome-look.org/CONTENT/content-files/121881-equinox-$EQUINOX_ENGINE_VERSION.tar.gz
displayandexec "Décompression Equinox Engine v$EQUINOX_ENGINE_VERSION" tar zxvf 121881-equinox-$EQUINOX_ENGINE_VERSION.tar.gz
cd equinox-$EQUINOX_ENGINE_VERSION
displayandexec "Configuration Equinox Engine v$EQUINOX_ENGINE_VERSION" ./configure --prefix=/usr --enable-animation
displayandexec "Compilation/Installation Equinox Engine v$EQUINOX_ENGINE_VERSION" make install
rm -rf 121881-equinox-$EQUINOX_ENGINE_VERSION.tar.gz equinox-$EQUINOX_ENGINE_VERSION
displayandexec "Téléchargement Equinox Theme v$EQUINOX_THEME_VERSION" $WGET http://gnome-look.org/CONTENT/content-files/140449-equinox-themes-$EQUINOX_THEME_VERSION.tar.gz
displayandexec "Décompression Equinox Theme v$EQUINOX_THEME_VERSION" tar zxvf 140449-equinox-themes-$EQUINOX_THEME_VERSION.tar.gz
displayandexec "Installation Equinox Theme v$EQUINOX_THEME_VERSION" cp -R Equinox* /usr/share/themes/
rm -rf 140449-equinox-themes-$EQUINOX_THEME_VERSION.tar.gz
displayandexec "Téléchargement icones Faenza v$FAENZA_VERSION" $WGET http://faenza-icon-theme.googlecode.com/files/faenza-icon-theme_$FAENZA_VERSION.tar.gz
displayandexec "Décompression icones Faenza v$FAENZA_VERSION" tar zxvf faenza-icon-theme_$FAENZA_VERSION.tar.gz
displayandexec "Installation icones Faenza v$FAENZA_VERSION" cp -R Faenza* /usr/share/icons/
rm -rf faenza-icon-theme_$FAENZA_VERSION.tar.gz Faenza* AUTHORS COPYING ChangeLog README
displayandexec "Téléchargement du fond d'écran" $WGET -O /usr/share/backgrounds/wallpaper.jpg https://raw.github.com/nicolargo/debianpostinstall/master/wallpaper.jpg
displayandexec "Installation du fond d'écran" gconftool-2 -t string -s /desktop/gnome/background/picture_filename /usr/share/backgrounds/wallpaper.jpg

# Conkyc
# Theme LUA 2011 - http://gnome-look.org/content/show.php?content=141411
displayandexec "Téléchargement théme Conky" $WGET http://gnome-look.org/CONTENT/content-files/141411-Conky-lua%202011%20next%20generation.tar.gz
displayandexec "Décompression théme Conky" tar zxvf "141411-Conky-lua 2011 next generation.tar.gz"
displayandexec "Création des répertoires Conky" "mkdir -p $HOME_PATH/.lua ; mkdir -p $HOME_PATH/.lua/scripts ; mkdir -p $HOME_PATH/.conky"
displayandexec "Installation théme Conky" "cp 'Conky-lua 2011 next generation/Debian/logo.png' $HOME_PATH/.conky ; cp 'Conky-lua 2011 next generation/Debian/clock_rings.lua' $HOME_PATH/.lua/scripts ; cp 'Conky-lua 2011 next generation/Debian/conkyrc' $HOME_PATH/.conkyrc"
rm -rf "141411-Conky-lua 2011 next generation.tar.gz" "Conky-lua 2011 next generation"
chown -fR $USERNAME:$USERNAME $HOME_PATH/.lua
chown -fR $USERNAME:$USERNAME $HOME_PATH/.conky
chown -fR $USERNAME:$USERNAME $HOME_PATH/.conkyrc
displayandexec "Lancement de Conky" "/usr/bin/conky &"

# Connect Spotify to Chromium
displayandexec "Configuration de Chromium pour ouvrir les lien Spotify" "gconftool-2 -t string -s /desktop/gnome/url-handlers/spotify/command '/usr/bin/spotify -uri %s' ; gconftool-2 -t bool -s /desktop/gnome/url-handlers/spotify/needs_terminal false ; gconftool-2 -t bool -s /desktop/gnome/url-handlers/spotify/enabled true"

# Install TextAdept
if [ `arch` == "x86_64" ]; then
  TEXTADEPT_VERSION=$TEXTADEPT_VERSION".x86_64"
fi
displayandexec "Téléchargement de TextAdept v$TEXTADEPT_VERSION" $WGET http://textadept.googlecode.com/files/textadept_$TEXTADEPT_VERSION.tgz
displayandexec "Installation de TextAdept v$TEXTADEPT_VERSION" "tar zxvf textadept_$TEXTADEPT_VERSION.tgz ; rm -rf /opt/textadept ; mv textadept_$TEXTADEPT_VERSION /opt/textadept ; rm -f /usr/local/bin/textadept ; ln -s /opt/textadept/textadept /usr/local/bin/textadept"

# Custom .bashrc
cat >> $HOME_PATH/.bash_aliases << EOF
alias ll='ls -lF'
export MOZ_DISABLE_PANGO=1
EOF
source $HOME_PATH/.bashrc

echo ""
echo "##############################################################################"
echo ""
echo "                            Fin du script (version $VERSION)"
echo ""
echo " 1) Automatiser lancement > sh -c \"sleep 30; /usr/bin/conky\" <";
echo "    dans Système > Préférences > Application au démarrage"
echo " 2) Redémarrer la machine"
echo " 3) Selectionner le thème GTL: Système > Préférence > Apparence"
echo "       - Thème > Equinox Evolution Dawn"
echo " 4) Installer Dropbox sur votre session: Applications > Internet > Dropbox"
echo ""
echo " Le log du script se trouve dans le fichier:"
echo "    $LOG_FILE"
echo ""
echo "##############################################################################"
echo ""

echo "Fin du script" >> $LOG_FILE

# The end...
############
