package Dist::Zilla::PluginBundle::Author::HAYOBAAN;
use strict;
use warnings;

# ABSTRACT: Hayo Baan's Dist::Zilla configuration
# VERSION

=for test_synopsis
my @HAYOBAAN;

=head1 DESCRIPTION

This is a L<Dist::Zilla> PluginBundle. It installs and configures
L<Dist::Zilla> plugins according to HAYOBAAN's preferences.

=head1 USAGE

  # In dist.ini
  [@Author::HAYOBAAN]

=head1 OPTIONS

The following additional command-line option is available for the C<dzil> command.

=head2 C<--local>, C<local_only>, C<local_release>, or C<--local_release_only>

Adding this option to the C<dzil release> command will:

=for :list
* inhibit uploading to CPAN (if applicable),
* inhibit git checking, tagging, commiting, and pushing,
* inhibit Changes file checking
* keep the version number the same.

The C<run_after_release> code is still run so you can use this flag to
"release" a development version locally for further use or testing,
without e.g., increasing the version number.

=head1 STABILITY

This module is still under development.

=head1 CREDITS

I took inspiration from many people's L<Dist::Zilla> and L<Pod::Weaver> PluginBundles. Most notably from:

=for :list
* David Golden L<DAGOLDEN|https://metacpan.org/pod/Dist::Zilla::PluginBundle::DAGOLDEN>
* Mike Dohorty L<DOHORTY|https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::DOHORTY>

=cut

use Getopt::Long;

use Moose 0.99;
use namespace::autoclean 0.09;
use Dist::Zilla 5.014; # default_jobs
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub mvp_multivalue_args { qw(git_remote run_after_build run_after_release additional_test disable_test) }

sub mvp_aliases {
    {
        local         => "local_release_only",
        local_only    => "local_release_only",
        local_release => "local_release_only",
    }
}

=for Pod::Coverage mvp_multivalue_args mvp_aliases

=attr is_cpan

Specifies that this is a distribution that is destined for CPAN. When
true, releases are uploaded to CPAN using
L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>. If false, releases
are made using L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>.

Default: I<false>.

=cut

has is_cpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{is_cpan} },
);

=attr is_github_hosted

Specifies that the distribution's repository is hosted on GitHub.

Default: I<false> (note: setting C<is_cpan> enforces C<is_github_hosted>
to I<true>)

=cut

has is_github_hosted => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{is_github} || $_[0]->is_cpan },
);

=attr git_remote

Specifies where to push the distribution on GitHub. Can be used
multiple times to upload to multiple branches.

Default: C<origin>

=cut

has git_remote => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { $_[0]->payload->{git_remote} // [ 'origin' ] },
);

=attr no_git

Specifies that the distribution is not under git version control.

Default: I<false> (note: setting C<is_github_hosted> enforces this
setting to I<false>)

=cut

has no_git => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{no_git} && !$_[0]->is_github_hosted },
);

=attr local_release_only

Setting this to I<true> will:

=for :list
* inhibit uploading to CPAN (if applicable),
* inhibit git checking, tagging, commiting, and pushing,
* keep the version number the same,

when I<releasing> the distribution.

=cut

has local_release_only => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{local_release_only} }
);

=attr run_after_build

Specifies commands to run after the release has been built (but not yet released). Multiple
C<run_after_build> commands can be specified.

The commands are run from the root of your development tree and has the following special symbols available:

=for :list
* C<%d> the directory in which the distribution was built
* C<%n> the name of the distribution
* C<%p> path separator ('/' on Unix, '\\' on Win32... useful for cross-platform dist.ini files)
* C<%v> the version of the distribution
* C<%t> -TRIAL if the release is a trial release, otherwise the empty string
* C<%x> full path to the current perl interpreter (like $^X but from Config)

Default: I<nothing>

=cut

has run_after_build => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { $_[0]->payload->{run_after_build} // [] },
);

=attr run_after_release

Specifies commands to run after the release has been made. Use it to e.g.,
automatically install your distibution after releasing. Multiple
run_after_release commands can be specified.

The commands are run from the root of your development tree and has
the same symbols available as the C<run_after_build>, plus the
following:

=for :list
* C<%a> the archive of the release

Default: C<cpanm './%d'>

=head3 Examples:

To install using cpanm (this is the default):

  run_after_release = cpanm './%d'

To install using cpan:

  run_after_release = %x -MCPAN -einstall './%d'

To not do anything:

  run_after_release =

=cut

has run_after_release => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { exists $_[0]->payload->{run_after_release} ? $_[0]->payload->{run_after_release} : [ 'cpanm ./%d' ] },
);

=attr additional_test

Additional test plugin to use. Can be used multiple times.

By default the following tests are executed:

=for :list
* C<Test::Compile> -- Checks if perl code compiles correctly
* C<Test::Perl::Critic> -- Checks Perl source code for best-practices
* C<Test::EOL> -- Checks line endings
* C<Test::NoTabs> -- Checks for the use of tabs
* C<Test::Version> -- Checks to see if each module has the correct version set
* C<Test::MinimumVersion> -- Checks the minimum perl version, using C<max_target_perl>
* C<MojibakeTests> -- Checks source encoding
* C<Test::Kwalitee> -- Checks the Kwalitee
* C<Test::Portability> -- Checks portability of code
* C<Test::UnusedVars> -- Checks for unused variables
* C<Test::CPAN::Changes> -- Validation of the Changes file
* C<Test::DistManifest> -- Validation of the MANIFEST file
* C<Test::CPAN::Meta::JSON> -- Validation of the META.json file -- only when hosted on GitHub
* C<MetaTests> -- Validation of the META.yml file -- only when hosted on GitHub
* C<PodSyntaxTests> -- Checks pod syntax
* C<PodCoverageTests> -- Checks pod coverage
* C<Test::Pod::LinkCheck> -- Checks pod links
* C<Test::Synopsis> -- Checks the pod synopsis

=cut

has additional_test => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { $_[0]->payload->{additional_test} // [] },
);

=attr disable_test

Specifies the tests you don't want to run.

Default: I<none> (i.e., run all default and C<additional_test> tests).

=cut

has disable_test => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { $_[0]->payload->{disable_test} // [] },
);

=attr max_target_perl

Defines the highest minimum version of perl you intend to require.
This is passed to L<Dist::Zilla::Plugin::Test::MinimumVersion>, which generates
a F<minimum-version.t> test that'll warn you if you accidentally used features
from a higher version of perl than you wanted. (Having a lower required version
of perl is okay.)

Default: C<5.10>

=cut

has max_target_perl => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{max_target_perl} // '5.10.' },
);

=attr weaver_config

Specifies the configuration for L<Pod::Weaver>.

Default: C<@Author::HAYOBAAN>.

=cut

has weaver_config => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{weaver_config} // '@Author::HAYOBAAN' },
);

=attr tag_format

Specifies the format for tagging a release (see
L<Git::Tag|Dist::Zilla::Plugin::Git::Tag> for details).

Default: C<v%v%t>

=cut

has tag_format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{tag_format} // 'v%v%t' },
);

=attr version_regexp

Specifies the regexp for versions (see
L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion> for details).

Default: C<^v?([\d.]+)(?:-TRIAL)?$>

Note: only used in case of git version controlled repositories
(L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> is used in case of
non-git version controlled repositories).

=cut

has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{version_regexp} // '^v?([\d.]+)(?:-TRIAL)?$' },
);

################################################################################

# List of files to copy to the root after they were built.
has copy_build_files => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [ qw(Build.PL Makefile.PL README README.mkdn) ] },
);

# Files to exclude from gatherer
has exclude_files => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [
        @{$_[0]->copy_build_files},
        qw(MANIFEST),
    ] },
);

# Files that can be "dirty"
has allow_dirty => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [
        @{$_[0]->copy_build_files},
        qw(dist.ini Changes),
    ] },
);

# Directories that should not be indexed
has meta_no_index_dirs => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [ qw(corpus) ] },
);

# Helper function to add a test, checks for disabled tests
sub _add_test {
    my $self = shift;
    map {
        my $plugin = ref $_ ? $_->[0] : $_;
        grep /^$plugin$/, @{$self->disable_test} ? () : $_;
    } @_;
}

=for Pod::Coverage configure

=cut

sub configure {
    my $self = shift;

    {
        my $local;
        GetOptions('local|local_only|local_release|local-release-only!' => \$local);
        $self->local_release_only($local) if defined $local;
    }

    $self->add_plugins(
        #### Version ####
        !$self->no_git ? (
            # Provide a version number by bumping the last git release tag
            [
                'Git::NextVersion' => {
                    first_version     => 0.001,                 # First version = 0.001
                    version_by_branch => 0,                     # Set to 1 if doing maintenance branch
                    version_regexp    => $self->version_regexp, # Regexp for version format
                },
            ],
        ) : (
            # Provide automatic version based on date
            'AutoVersion'
        ),

        # Adds version to file (no line insertion, using our)
        'OurPkgVersion',

        #### Gather & Prune ####
        # Gather files to include
        [ 'GatherDir' => { exclude_filename => $self->exclude_files } ],
        # Remove cruft
        'PruneCruft',
        # Skip files in MANIFEST.SKIP
        'ManifestSkip',

        #### PodWeaver ####
        # Automatically extends POD
        [
            'PodWeaver' => {
                config_plugin      => '@Author::HAYOBAAN',
                replacer           => 'replace_with_comment',
                post_code_replacer => 'replace_with_nothing',
            }
        ],

        #### Distribution Files & Metadata ####
        # Create README and README.mkdn from POD
        [ 'ReadmeAnyFromPod', 'Text' ],
        [ 'ReadmeAnyFromPod', 'Markdown' ],

        $self->is_github_hosted ? (
            # Create a LICENSE file
            'License',
            # Create an INSTALL file
            'InstallGuide',
        ) : (),

        # Automatically determine minimum perl version
        'MinimumPerl',
        # Automatically determine prerequisites
        'AutoPrereqs',

        $self->is_github_hosted ? (
            # Add GitHub metadata",
            'GitHub::Meta',
            # Add META.json",
            'MetaJSON',
            # Add META.yaml",
            'MetaYAML',
            # Add provided Packages to META.*",
            'MetaProvides::Package',
            # Add provided Classes to META.*",
            'MetaProvides::Class',
        ) : (),

        # Do not index certain dirs",
        [ 'MetaNoIndex' => { dir => $self->meta_no_index_dirs } ],

        #### Build System ####
        # Install content of bin directory as executables
        'ExecDir',
        # Install content of share directory as sharedir
        'ShareDir',
        # Build a Makefile.PL that uses ExtUtils::MakeMaker
        [ 'MakeMaker', { default_jobs => 9 } ],
        # Build a Build.PL that uses Module::Build
        'ModuleBuild',

        # Add Manifest
        'Manifest',

        #### After Build ####
        # Copy/move specific files after building them
        [ 'CopyFilesFromBuild' => { copy => $self->copy_build_files } ],

        @{$self->run_after_build} ? (
            # Run specified commands
            [ 'Run::AfterBuild' => { run => $self->run_after_build } ],
        ) : (),

        #### Before Release Tests ####
        !$self->local_release_only ? (
            # Check if Changes file has content
            'CheckChangesHasContent',
        ) : (),

        # Check git repository before releasing
        !$self->no_git && !$self->local_release_only ? (
            [ 'Git::Check' => { allow_dirty => $self->allow_dirty } ],
        ) : (),

        # Extra test (gatherdir)
        # Checks if perl code compiles correctly
        $self->_add_test('Test::Compile'),

        # Extra tests (author)
        # Checks Perl source code for best-practices
        $self->_add_test('Test::Perl::Critic'),
        # Checks line endings
        $self->_add_test('Test::EOL'),
        # Checks for the use of tabs
        $self->_add_test('Test::NoTabs'),

        # Extra tests (release)
        # Checks to see if each module has the correct version set
        $self->_add_test('Test::Version'),
        # Checks the minimum perl version
        $self->_add_test([ 'Test::MinimumVersion' => { max_target_perl => $self->max_target_perl } ]),
        # Checks source encoding
        $self->_add_test('MojibakeTests'),
        # Checks the Kwalitee
        $self->_add_test('Test::Kwalitee'),
        # Checks portability of code
        $self->_add_test('Test::Portability'),
        # Checks for unused variables
        $self->_add_test('Test::UnusedVars'),
        !$self->local_release_only ? (
            # Validation of the Changes file
            $self->_add_test('Test::CPAN::Changes'),
        ) : (),
        # Validation of the MANIFEST file
        $self->_add_test('Test::DistManifest'),

        $self->is_github_hosted ? (
            # Validation of the META.json file
            $self->_add_test('Test::CPAN::Meta::JSON'),
            # Validation of the META.yml file
            $self->_add_test('MetaTests'),
        ) : (),

        # Checks pod syntax
        $self->_add_test('PodSyntaxTests'),
        # Checks pod coverage
        $self->_add_test('PodCoverageTests'),
        # Checks pod links
        $self->_add_test('Test::Pod::LinkCheck'),
        # Checks the pod synopsis
        $self->_add_test('Test::Synopsis'),

        # Add the additional tests specified
        @{$self->additional_test} ? $self->_add_test(@{$self->additional_test}) : (),

        #### Run tests ####
        # Run provided tests in /t directort before releasing
        'TestRelease',

        # Run the extra tests
        [ 'RunExtraTests' => { default_jobs => 9 } ],

        #### Release ####
        !$self->local_release_only ? (
            # Prompt for confirmation before releasing
            'ConfirmRelease',
        ) : (),
        $self->is_cpan && !$self->local_release_only ? (
            # Upload release to CPAN,
            'UploadToCPAN',
            # Provide statistics
            'SchwartzRatio',
        ) : (
            # Fake release
            'FakeRelease',
        ),

        #### After release ###
        !$self->local_release_only ? (
            # Update the next release number in the changelog
            [ 'NextRelease' => { format => '%-9v %{yyyy-MM-dd}d' } ],
        ) : (),

        !$self->no_git && !$self->local_release_only ? (
            # Commit dirty files
            [ 'Git::Commit' => { allow_dirty => $self->allow_dirty } ],
            # Tag the new version
            [
                'Git::Tag' => {
                    tag_format  => $self->tag_format,
                    tag_message => 'Released ' . $self->tag_format,
                }
            ],
        ) : (),

        $self->is_github_hosted && @{$self->git_remote} && !$self->local_release_only ? (
            # Push current branch
            [ 'Git::Push', { push_to => $self->git_remote } ],
        ) : (),

        $self->is_cpan && !$self->local_release_only ? (
            # Update GitHub repository info on release
            [ 'GitHub::Update' => { metacpan => 1 } ]
        ) : (),

        @{$self->run_after_release} ? (
            # Install the release
            [ 'Run::AfterRelease' => { run => $self->run_after_release } ],
        ) : (),

        # Cleanup
        'Clean',
    );
}

1;