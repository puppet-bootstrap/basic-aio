# @summary Install an OpenVox package
#
# Uses the `openvox_bootstrap::install` task.  With `manage_repos` (the
# default), the task installs the release package for `collection` from
# yum.voxpupuli.org or apt.voxpupuli.org.  Without it, the task skips the
# release package and installs from whatever repositories the target's package
# manager already has, such as a Satellite or other local mirror.  That works
# on hosts that can't reach the internet.
#
# @param targets The targets to install the package on
# @param package The package to install
# @param version
#   The version to install.  Defaults to the latest available version, or the
#   installed version if the package is already installed.
# @param collection
#   The OpenVox collection (`openvox9`, for example).  Only used with
#   `manage_repos`.
# @param manage_repos Set up the OpenVox package repository on the targets
# @param force_release_package
#   With `manage_repos`, reinstall the release package even if it is already
#   installed
plan bootstrap::install_packages (
  TargetSpec          $targets,
  String[1]           $package,
  Optional[String[1]] $version               = undef,
  Optional[String[1]] $collection            = undef,
  Boolean             $manage_repos          = true,
  Boolean             $force_release_package = true,
) {
  # Leave out unset parameters: tasks that read their input from the
  # environment would see the string `null`.
  $install_params = {
    'package'                => $package,
    'version'                => $version ? {
      undef   => 'latest',
      default => $version,
    },
    'collection'             => $collection,
    'manage_release_package' => $manage_repos,
    'force_release_package'  => $force_release_package,
  }.filter |$key, $value| { $value =~ NotUndef }

  $description = $manage_repos ? {
    true    => "Installing ${package}",
    default => "Installing ${package} from the configured repositories",
  }

  run_task('openvox_bootstrap::install', $targets, $description, $install_params)
}
