# this class will setup lxde on Ubuntu
# kiosk_mode = set up automatic login (optional)
# kiosk_user = user to automatically login as
# kiosk_app = application to run automatically at login (optional)
# kiosk_home = home directory, if not /home (optional)
# pamfix = apply https://bugs.launchpad.net/ubuntu/+source/policykit-desktop-privileges/+bug/1240336/comments/32
class lxde (
  $kiosk_mode   = false,
  $kiosk_user   = false,
  $kiosk_app    = false,
  $kiosk_home   = false,
  $lxdmpackages = [ 'lxde', 'lxterminal', 'policykit-desktop-privileges', 'policykit-1-gnome', 'udisks2', 'upower' ],
  $lxdmconf     = '/etc/lxdm/lxdm.conf',
  $pamfix       = true
) {
  if $::operatingsystem != 'Ubuntu' {
    fail("The ${module_name} module is not supported on an ${::operatingsystem} based system.")
  }

  package { $lxdmpackages:
    ensure  => 'present',
  }

  if $kiosk_mode {
    if ! $kiosk_user {
      fail("Username for kiosk mode not provided to ${module_name}")
    }

    augeas { 'lxdm autologin':
      changes => "set /files/${lxdmconf}/base/autologin ${kiosk_user}",
      lens    => 'Puppet.lns',
      incl    => $lxdmconf,
      require => Package[$lxdmpackages],
    }

    if $kiosk_app {
      if $kiosk_home {
        $_home = $kiosk_home
      } else {
        $_home = "/home/${kiosk_user}"
      }

      file { "${_home}/.config/autostart/kioskapp.desktop":
        ensure  => 'present',
        owner   => $kiosk_user,
        content => template("${module_name}/autostart.erb")
      }
    }
  }

  if $pamfix {
    pam { 'lxdm fix 1':
      ensure => 'present',
      service => 'lxdm',
      type    => 'session',
      control => 'required',
      module  => 'pam_loginuid.so',
    }

    pam { 'lxdm fix 2':
      ensure => 'present',
      service => 'lxdm',
      type    => 'session',
      control => 'required',
      module  => 'pam_systemd.so',
    }
  }
}
