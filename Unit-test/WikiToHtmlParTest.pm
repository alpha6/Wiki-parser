#!/usr/bin/perl
package Wiki2HtmlParTest;

use lib qw(../lib);
use strict;
use warnings;

use base qw(Test::Unit::TestCase);

use xPeerlIo::xInWiki;
use xPeerlIo::xOut;
use xPeerlIo::xOutXhtml;


sub new {
    my $self = shift()->SUPER::new(@_);
    # your state for fixture here
    return $self;
}


sub wiki2Html{
	my$self=shift;
	my$IN=shift;
        my$baseConfig=$self->{'baseConfig'};
        my$OUT='';
	my$out=xPeerlIo::xOutXhtml->new($baseConfig,sub{$OUT.=$_[0]});
        my$xInWiki=xPeerlIo::xInWiki->new($baseConfig,$out);
	my@LN=();
	while($IN=~s/^(.*?\r?\n)//){
		push@LN,$1;
	}
	push@LN,$IN if''ne$IN;
	foreach(@LN){
		$xInWiki->line($_);
        }
	$xInWiki->flush();
        return$OUT;
}

sub set_up {
	my$self=shift;
	my$ROOTDIR='../';
	$self->{'baseConfig'}={
		'procRoot'=>$ROOTDIR.'/proc',
		'dataRoot'=>$ROOTDIR.'/var',
		'confRoot'=>$ROOTDIR.'/etc',
		'tempRoot'=>$ROOTDIR.'/tmp',
		'siteRoot'=>'/xNeu/htdocs',
		'siteUrl'=>'',
	};
}
sub test_ok_simple_par {
# простые тесты для абзацев
        my$self=shift;
        $self->assert_equals("<p>aaa</p>",$self->wiki2Html("aaa"));
        $self->assert_equals("<p>aaa\n</p>",$self->wiki2Html("aaa\n"));
        $self->assert_equals("\n<p>aaa</p>",$self->wiki2Html("\naaa"));
        $self->assert_equals("\n<p>aaa\n</p>",$self->wiki2Html("\naaa\n"));
        $self->assert_equals("<p>aaa\nbbb</p>",$self->wiki2Html("aaa\nbbb"));

        $self->assert_equals("<p>aaa\n</p>\n<p>bbb</p>",$self->wiki2Html("aaa\n\nbbb"));
        $self->assert_equals("<p>aaa\n</p>\n\n<p>bbb</p>",$self->wiki2Html("aaa\n\n\nbbb"));
        $self->assert_equals("<p>aaa\n</p>\n<p>bbb\n</p>",$self->wiki2Html("aaa\n\nbbb\n"));
}
sub test_ok_div_par {
# простые тесты для абзацев
        my$self=shift;
        $self->assert_equals("<div>\n<p>aaa\n</p><p>aaa\n</p></div>",$self->wiki2Html(
"::aaa
::
::aaa
"));
        $self->assert_equals("<div>\n\n<p>aaa\n</p><p>aaa\n</p></div>",$self->wiki2Html(
"::
::aaa
::
::aaa
"));
        $self->assert_equals("<div>\n<p>aaa\n</p><p>aaa\n</p>\n<p>aaa\n</p></div>",$self->wiki2Html(
"::aaa
::
::aaa
::
::aaa
::"));
#        $self->assert_equals("<div>\n<p>aaa\n</p><p>aaa\n</p>\n<p>aaa\n</p></div>",$self->wiki2Html(
#"::aaa
#::>>bbb
#::aaa
#::
#::aaa
#::"));
        $self->assert_equals("<div>aaa</div>",$self->wiki2Html("::aaa"));
#        $self->assert_equals("<p>aaa\n</p>",$self->wiki2Html("aaa\n"));
}
sub test_ok_no_par {
# простые тесты - без абзацев
        my$self=shift;
        $self->assert_equals("<h1>aaa\n</h1>",$self->wiki2Html(
"== aaa ==
"));
        $self->assert_equals("<ul><li>aaa\n</li></ul>",$self->wiki2Html(
"  * aaa
"));
        $self->assert_equals("<div>aaa</div>",$self->wiki2Html("::aaa"));
#        $self->assert_equals("<p>aaa\n</p>",$self->wiki2Html("aaa\n"));
}
sub test_ok_styled_par {
# простые тесты для абзацев
# цель - проверить поддержку стилей абзацев
        my$self=shift;
	return 1;	
        $self->assert_equals("<p style=\"x\">aaa</p>",$self->wiki2Html("{x}\naaa"));
        $self->assert_equals("<p style=\"x\">aaa\n</p>",$self->wiki2Html("{x}\naaa\n"));
}

sub tear_down {
    # clean up after test
}

1;
