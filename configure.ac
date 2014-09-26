dnl Process this file with autoconf to produce a configure script.
AC_REVISION ($Revision: 1.150 $)
AC_PREREQ(2.58)
AC_INIT(check_nwc_health,3.1)
AM_INIT_AUTOMAKE([1.9 tar-pax])
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
AC_ARG_WITH(noinst_level,
  ACX_HELP_STRING([--with-noinst-level=LEVEL],
    [error level if nwc_health is not installed]),
  with_noinst_level=$withval,
  with_noinst_level=unknown)
AC_SUBST(NOINSTLEVEL, $with_noinst_level)
AC_ARG_WITH(degrees,
  ACX_HELP_STRING([--with-degrees=UNIT],
    [which temperature unit to use. (celsius or fahrenheit)]),
  with_degrees=$withval,
  with_degrees=unknown)
case "$with_degrees" in
  fahrenheit)
    AC_SUBST(CELSIUS, 0)
    ;;
  *)
    AC_SUBST(CELSIUS, 1)
    ;;
esac
AC_ARG_ENABLE([perfdata],
[  --enable-perfdata       wether to output perfdata (default=no)], ,enable_perfdata=no)
if test x"$enable_perfdata" = xyes ; then
  AC_SUBST(PERFDATA, 1)
else
  AC_SUBST(PERFDATA, 0)
fi
AC_ARG_ENABLE([extendedinfo],
[  --enable-extendedinfo   wether to output extended info (default=no)], ,enable_extendedinfo=no)
if test x"$enable_extendedinfo" = xyes ; then
  AC_SUBST(EXTENDEDINFO, 1)
else
  AC_SUBST(EXTENDEDINFO, 0)
fi
AC_ARG_ENABLE([hwinfo],
[  --disable-hwinfo        wether to output model desc., serial no., bios version (default=yes)], ,enable_hwinfo=yes)

if test x"$enable_hwinfo" = xyes ; then
  AC_SUBST(HWINFO, 1)
else
  AC_SUBST(HWINFO, 0)
fi


case "$host_os" in 
  *hp*)
    defaulttrustedpath=/bin:/sbin:/usr/bin:/usr/sbin:/usr/contrib/bin
    ;;
  *)
    defaulttrustedpath=/bin:/sbin:/usr/bin:/usr/sbin
    ;;
esac

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

AC_OUTPUT(Makefile plugins-scripts/Makefile plugins-scripts/subst)

ACX_FEATURE([with],[perl])
ACX_FEATURE([with],[nagios-user])
ACX_FEATURE([with],[nagios-group])
ACX_FEATURE([with],[noinst-level])
ACX_FEATURE([with],[degrees])
ACX_FEATURE([enable],[perfdata])
ACX_FEATURE([enable],[extendedinfo])
ACX_FEATURE([enable],[hwinfo])
