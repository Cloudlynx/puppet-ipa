# Definition: ipa::replicainstall
#
# Installs an IPA replica
define ipa::replicainstall (
  $host    = $name,
  $adminpw = {},
  $dspw    = {}
) {

  $file = "/var/lib/ipa/replica-info-${host}.gpg"

  Exec["replicainfocheck-${host}"] ~> Exec["replicainstall-${host}"]

  exec { "replicainfocheck-${host}":
    command   => "/usr/bin/test -e ${file}",
    tries     => '60',
    try_sleep => '60',
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1'
  }

  exec { "replicainstall-${host}":
    command     => "/usr/sbin/ipa-replica-install --admin-password=${adminpw} --password=${dspw} --skip-conncheck --unattended ${file}",
    timeout     => '0',
    logoutput   => 'on_failure',
    refreshonly => true
  }
}
