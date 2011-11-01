#!/usr/bin/perl
package CoreLibTest;

use lib qw(../lib);
use strict;
use warnings;

use base qw(Test::Unit::TestCase);

use xPeerl::xCoreLib;


sub new {
    my $self = shift()->SUPER::new(@_);
    # your state for fixture here
    return $self;
}




sub set_up {
	my$self=shift;
}
sub test_url_unescape_ok {
	my$self=shift;

	my$in='%20%210++a%3D%3d%2';
	my$in0=$in;
	my$out=&xUrlUnEscape($in);
	$self->assert_equals(" !0  a==\%2",$out);
	$self->assert_equals($in,$in0);
	&xDoUrlUnEscape($in);
	$self->assert_equals($in,$out);
}
#sub test_url_escape_ok {
#	my$self=shift;
#
#	my$in=' !0  a==2';
#	my$in0=$in;
#	my$out=&xUrlEscape($in);
#	$self->assert_equals("%20%210++a%3D%3d2",$out);
#	$self->assert_equals($in,$in0);
#	&xDoUrlEscape($in);
#	$self->assert_equals($in,$out);
#}
sub test_html_unescape_ok {
	my$self=shift;

	my$in="&amp;&#38;\n&gt;&#62;&lt;&#60;&quot;&#34;";
	my$in0=$in;
	my$out=&xHtmlUnEscape($in);
	$self->assert_equals("&&\n>><<\"\"",$out);
	$self->assert_equals($in,$in0);
	&xDoHtmlUnEscape($in);
	$self->assert_equals($in,$out);
}
sub test_html_escape_ok {
	my$self=shift;

	my$in="&&\n>><<\"\"";
	my$in0=$in;
	my$out=&xHtmlEscape($in);
	$self->assert_equals("&amp;&amp;\n&gt;&gt;&lt;&lt;&quot;&quot;",$out);
	$self->assert_equals($in,$in0);
	&xDoHtmlEscape($in);
	$self->assert_equals($in,$out);
}
#sub test_htmlattr_unescape_ok {
#	my$self=shift;

#	my$in="&amp;&#38;&#10;&#13;&gt;&#62;&#9;&lt;&#60;&quot;&#34;&#0;";
#	my$in0=$in;
#	my$out=&xHtmlAttrUnEscape($in);
#	$self->assert_equals("&&\n\r>>\011<<\"\"\000",$out);
#	$self->assert_equals($in,$in0);
#	&xDoHtmlAttrUnEscape($in);
#	$self->assert_equals($in,$out);
#}
sub test_htmlattr_escape_ok {
	my$self=shift;

	my$in="&&\n\r>>\011<<\"\"\000";
	my$in0=$in;
	my$out=&xHtmlAttrEscape($in);
	$self->assert_equals("&amp;&amp;&#10;&#13;&gt;&gt;&#9;&lt;&lt;&quot;&quot;&#0;",$out);
	$self->assert_equals($in,$in0);
	&xDoHtmlAttrEscape($in);
	$self->assert_equals($in,$out);
}
#sub test_unescape_ok {
#	my$self=shift;
#
#	my$in='a123\r\n\'\"\000\\';
#	my$in0=$in;
#	my$out=&xUnEscape($in);
#	$self->assert_equals("a123\r\n\'\"\000\\",$out);
#	$self->assert_equals($in,$in0);
#	&xDoUnEscape($in);
#	$self->assert_equals($in,$out);
#}
sub test_escape_ok {
	my$self=shift;

	my$in="a123\r\n\'\"\000\\";
	my$in0=$in;
	my$out=&xEscape($in);
	$self->assert_equals("a123\\r\\n\\\'\\\"\\000\\\\",$out);
	$self->assert_equals($in,$in0);
	&xDoEscape($in);
	$self->assert_equals($in,$out);
}
sub test_resolve_path_ok {
	my$self=shift;
	$self->assert_equals('/a/b/',&xResolvePath('/c/d/e/../../../x/././../a/v/d/././../../b/c/x/../..'));
	$self->assert_equals('/a/b/',&xResolvePath('v/d/././../////../b/c/x/../..','/a/'));
	$self->assert(!defined&xResolvePath('/d/././../../b/c/x/../..','/a/'));
}
1;