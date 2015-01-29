# Class: ipa::replica
#
# This class configures an IPA replica
#
# Parameters:
#
# Actions:
#
# Requires: Exported resources, puppetlabs/puppetlabs-firewall, puppetlabs/stdlib
#
# Sample Usage:
#
class ipa::replica (
  $svrpkg      = {},
  $bindpkgs    = {},
  $adminpw     = {},
  $dspw        = {},
  $domain      = {},
  $kstart      = {},
  $sssd        = {},
  $dns         = {},
  $forwarders  = [],
  $ntp         = {},
  $extca       = {},
) {

  Class['ipa::client'] -> Ipa::Masterprincipal <<| tag == "ipa-master-principal-${ipa::replica::domain}" |>> -> Ipa::Replicapreparefirewall <<| tag == "ipa-replica-prepare-firewall-${ipa::replica::domain}" |>> -> Ipa::Masterreplicationfirewall <<| tag == "ipa-master-replication-firewall-${ipa::replica::domain}" |>> -> Ipa::Replicainstall[$::fqdn] -> Service['ipa']

  Ipa::Replicapreparefirewall <<| tag == "ipa-replica-prepare-firewall-${ipa::replica::domain}" |>>
  Ipa::Masterreplicationfirewall <<| tag == "ipa-master-replication-firewall-${ipa::replica::domain}" |>>
  Ipa::Masterprincipal <<| tag == "ipa-master-principal-${ipa::replica::domain}" |>>

  if $::osfamily != "RedHat" {
    fail("Cannot configure an IPA replica server on ${::operatingsystem} operating systems. Must be a RedHat-like operating system.")
  }

  realize Package[$ipa::replica::svrpkg]

  realize Service['ipa']

  if $ipa::replica::kstart {
    realize Package["kstart"]
  }

  if $ipa::replica::sssd {
    realize Package['sssd-common']
    realize Service["sssd"]
  }

  firewall { "101 allow IPA replica TCP services (kerberos,kpasswd,ldap,ldaps)":
    ensure => 'present',
    action => 'accept',
    proto  => 'tcp',
    dport  => ['80','88','389','443','464','636','53']
  }

  firewall { "102 allow IPA replica UDP services (kerberos,kpasswd,ntp)":
    ensure => 'present',
    action => 'accept',
    proto  => 'udp',
    dport  => ['88','123','464','53']
  }

  if $ipa::replica::dns {
    realize Package[$bindpkgs]
    if size($ipa::replica::forwarders) > 0 {
      $forwarderopts = join(prefix($ipa::replica::forwarders, '--forwarder '), ' ')
    }
    else {
      $forwarderopts = '--no-forwarders'
    }
    $dnsopt = '--setup-dns'
  }
  else {
    $dnsopt = ''
    $forwarderopts = ''
  }

  $ntpopt = $ipa::replica::ntp ? {
    false   => '--no-ntp',
    default => ''
  }

  $extcaopt = $extca ? {
    false   => '--setup-ca',
    default => ''
  }

  ipa::replicainstall { "$::fqdn":
    adminpw       => $ipa::replica::adminpw,
    dspw          => $ipa::replica::dspw,
    forwarderopts => $ipa::replica::forwarderopts,
    dnsopt        => $ipa::replica::dnsopt,
    ntpopt        => $ipa::replica::ntpopt,
    extcaopt      => $ipa::replica::extcaopt,
    require       => Package[$ipa::replica::svrpkg]
  }

  @@ipa::replicareplicationfirewall { "$::fqdn":
    source => $::ipaddress,
    tag    => "ipa-replica-replication-firewall-${ipa::replica::domain}"
  }

  @@ipa::replicaprepare { "$::fqdn":
    dspw => $ipa::replica::dspw,
    tag  => "ipa-replica-prepare-${ipa::replica::domain}"
  }
}
