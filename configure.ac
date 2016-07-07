dnl Process this file with autoconf to produce a configure script.
AC_REVISION ($Revision: 1.150 $)
AC_PREREQ(2.58)
AC_INIT(check_nwc_health,5.7.1.3)
AM_INIT_AUTOMAKE([1.9 tar-pax])
AM_MAINTAINER_MODE([disable])
AC_CANONICAL_HOST

RELEASE=1
AC_SUBST(RELEASE)

AC_PREFIX_DEFAULT(/usr/local/nagios)

dnl Figure out how to invoke "install" and what install options to use.
AC_PROG_INSTALL
AC_SUBST(INSTALL)

AC_PROG_MAKE_SET
AC_PROG_AWK

WARRANTY="This plugin comes with ABSOLUTELY NO WARRANTY. You may redistribute\ncopies of the plugin under the terms of the GNU General Public License.\nFor more information about these matters, see the file named COPYING.\n"
AC_SUBST(WARRANTY)

SUPPORT="Send email to gerhard.lausser@consol.de if you have questions\nregarding use of this software.\nPlease include version information with all correspondence (when possible,\nuse output from the --version option of the plugin itself).\n"
AC_SUBST(SUPPORT)

AC_ARG_WITH(nagios_user,
  ACX_HELP_STRING([--with-nagios-user=USER],
    [set user name to run nagios]),
  with_nagios_user=$withval,
  with_nagios_user=nagios)
AC_ARG_WITH(nagios_group,
  ACX_HELP_STRING([--with-nagios-group=GROUP],
    [set group name to run nagios]),
  with_nagios_group=$withval,
  with_nagios_group=nagios)
AC_SUBST(with_nagios_user)
AC_SUBST(with_nagios_group)
INSTALL_OPTS="-o $with_nagios_user -g $with_nagios_group"
AC_SUBST(INSTALL_OPTS)

EXTRAS=
dnl PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/etc:/usr/local/bin:/usr/local/sbin:$PATH

dnl Checks for programs.
AC_PATH_PROG(SH,sh)
AC_PATH_PROG(PERL,perl)

dnl allow them to override the path of perl
AC_ARG_WITH(perl,
  ACX_HELP_STRING([--with-perl=PATH],
    [sets path to perl executable]),
  with_perl=$withval,with_perl=$PERL)
AC_SUBST(PERL, $with_perl)

AC_ARG_ENABLE([standalone],
    AS_HELP_STRING([--disable-standalone], [Disable feature standalone]))
AM_CONDITIONAL([DISABLE_STANDALONE], [test "$enable_standalone" = "no"])

AC_OUTPUT(Makefile plugins-scripts/Makefile plugins-scripts/subst)

ACX_FEATURE([with],[perl])
ACX_FEATURE([with],[nagios-user])
ACX_FEATURE([with],[nagios-group])
ACX_FEATURE([disable],[standalone], $disable_standalone)
