# Security Policy for the WWW::Mechanize distribution.

Report security issues by email to Andy Lester <andy at petdance.com>.

This is the Security Policy for WWW::Mechanize.

The latest version of the Security Policy can be found in the
[git repository for WWW::Mechanize](https://github.com/libwww-perl/WWW-Mechanize/blob/main/SECURITY.md).

This text is based on the CPAN Security Group's Guidelines for Adding
a Security Policy to Perl Distributions (version 1.3.0)
https://security.metacpan.org/docs/guides/security-policy-for-authors.html

# How to Report a Security Vulnerability

Security vulnerabilities can be reported to the current WWW::Mechanize
maintainers by using GitHub's **Report a vulnerability** submission form.
On the repository's main page, select **Security** tab and then
click on the button *Report a vulnerabity*.
Direct link: https://github.com/libwww-perl/WWW-Mechanize/security/advisories/new

Please include as many details as possible, including code samples
or test cases, so that we can reproduce the issue.  Check that your
report does not expose any sensitive data, such as passwords,
tokens, or personal information.

If you would like any help with triaging the issue, or if the issue
is being actively exploited, please copy the report to the CPAN
Security Group (CPANSec) at <cpan-security@security.metacpan.org>.

Please *do not* use the public issue reporting system on RT or
GitHub issues for reporting security vulnerabilities.

Please do not disclose the security vulnerability in public forums
until past any proposed date for public disclosure, or it has been
made public by the maintainers or CPANSec.  That includes patches or
pull requests.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainers aim to acknowledge your security report as soon as
possible.  However, this project is maintained by a people in
their spare time, and they cannot guarantee a rapid response.  If you
have not received a response from them within 14 days, then
please send a reminder to them and copy the report to CPANSec at
<cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an
acknowledgement, with a possible query for more information.  It
will not necessarily include any fixes for the issue.

The project maintainers may forward this issue to the security
contacts for other projects where we believe it is relevant.  This
may include embedded libraries, system libraries, prerequisite
modules or downstream software that uses this software.

They may also forward this issue to CPANSec.

# Which Software This Policy Applies To

Any security vulnerabilities in WWW::Mechanize are covered by this policy.

Security vulnerabilities in versions of any libraries that are
included in WWW::Mechanize are also covered by this policy.

Security vulnerabilities are considered anything that allows users
to execute unauthorised code, access unauthorised resources, or to
have an adverse impact on accessibility or performance of a system.

Security vulnerabilities in upstream software (prerequisite modules
or system libraries, or in Perl), are not covered by this policy
unless they affect WWW::Mechanize, or WWW::Mechanize can
be used to exploit vulnerabilities in them.

Security vulnerabilities in downstream software (any software that
uses WWW::Mechanize, or plugins to it that are not included with the
WWW::Mechanize distribution) are not covered by this policy.

## Supported Versions of WWW::Mechanize

The maintainers will only commit to releasing security fixes for
the latest version of WWW::Mechanize.

Note that the WWW::Mechanize project only supports major versions of Perl
starting from v5.8.0.  If a security fix requires us to increase
the minimum version of Perl that is supported, then we may do so.

# Installation and Usage Issues

The distribution metadata specifies minimum versions of
prerequisites that are required for WWW::Mechanize to work.  However, some
of these prerequisites may have security vulnerabilities, and you
should ensure that you are using up-to-date versions of these
prerequisites.

Where security vulnerabilities are known, the metadata may indicate
newer versions as recommended.

## Usage

Please see the software documentation for further information.
