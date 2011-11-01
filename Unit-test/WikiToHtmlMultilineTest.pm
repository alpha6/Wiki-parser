#!/usr/bin/perl
package Wiki2HtmlMultilineTest;

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
		'bodyParEnabled'=>0,
		'procRoot'=>$ROOTDIR.'/proc',
		'dataRoot'=>$ROOTDIR.'/var',
		'confRoot'=>$ROOTDIR.'/etc',
		'tempRoot'=>$ROOTDIR.'/tmp',
		'siteRoot'=>'/xNeu/htdocs',
		'siteUrl'=>'',
	};
}
sub test_ok_simple_text {
# простые тесты для многострочного текста
# цель - проверить поддержку концов строк
        my$self=shift;
        $self->assert_equals("aaa",$self->wiki2Html("aaa"));
        $self->assert_equals("\naaa",$self->wiki2Html("\naaa"));
        $self->assert_equals("aaa\n",$self->wiki2Html("aaa\n"));
        $self->assert_equals("\naaa\n",$self->wiki2Html("\naaa\n"));
        $self->assert_equals("\n\naaa\n",$self->wiki2Html("\n\naaa\n"));
        $self->assert_equals("\naaa\n\n",$self->wiki2Html("\naaa\n\n"));
        $self->assert_equals("\na\naa\n",$self->wiki2Html("\na\naa\n"));
        $self->assert_equals("\na\n\naa\n",$self->wiki2Html("\na\n\naa\n"));
        $self->assert_equals("\n\n\na\n\n\naa\n\n\n\n",$self->wiki2Html("\n\n\na\n\n\naa\n\n\n\n"));
}
sub test_ok_formatting_text {
# простые тесты для многострочного текста
# цель - проверить поддержку сброса по пустой строке
        my$self=shift;
        $self->assert_equals("<em>aaa bbb</em>",$self->wiki2Html("//aaa bbb//"));
        $self->assert_equals("<em>aaa\nbbb</em>",$self->wiki2Html("//aaa\nbbb//"));
        $self->assert_equals("<em>aaa\nbbb\nccc</em>",$self->wiki2Html("//aaa\nbbb\nccc//"));
        $self->assert_equals("//aaa\n\nbbb//",$self->wiki2Html("//aaa\n\nbbb//"));
}
sub test_ok_simply_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div>aaa\n</div>",
		$self->wiki2Html("::aaa\n"));
        $self->assert_equals(
		"<div>aaa\nbbb\nccc\n</div>",
		$self->wiki2Html("::aaa\n::bbb\n::ccc\n"));
        $self->assert_equals(
		"\n\n<div>aaa\nbbb\nccc\n</div>",
		$self->wiki2Html("\n\n::aaa\n::bbb\n::ccc\n"));
        $self->assert_equals(
		"\n\n<div>aaa\n</div>",
		$self->wiki2Html("\n\n::aaa\n"));
        $self->assert_equals(
		"<blockquote>bbb\n</blockquote>",
		$self->wiki2Html(">>bbb\n"));
}
sub test_ko_simply_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div>\n</div>aaa\n",
		$self->wiki2Html("::\naaa\n"));
        $self->assert_equals(
		"<div>{bClass}aaa\n</div>\n",
		$self->wiki2Html(":: {bClass}aaa\n\n"));
        $self->assert_equals(
		"<div>{bClassaaa\n</div>\n",
		$self->wiki2Html("::{bClassaaa\n\n"));
}
sub test_ok_classed_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div class=\"bClass\">aaa\n</div>\n",
		$self->wiki2Html("::{bClass}aaa\n\n"));
        $self->assert_equals(
		"<blockquote class=\"aClass\">bbb\n</blockquote>\n",
		$self->wiki2Html(">>{aClass}bbb\n\n"));
}
sub test_ok_classed_mixed_blocks {
        my$self=shift;
        $self->assert_equals(
		"<blockquote>aaa\n</blockquote>\n<blockquote>bbb\n</blockquote>\n",
		$self->wiki2Html(">>aaa\n\n>>bbb\n\n"));
        $self->assert_equals(
		"<div>a\n<div>aa\n<div>aaa\n</div></div><blockquote>bb\n</blockquote></div>",
		$self->wiki2Html("::a\n::::aa\n::::::aaa\n::>>bb\n"));
        $self->assert_equals(
		"<div><div><div>aaa\n</div></div><blockquote>bb\n</blockquote></div>",
		$self->wiki2Html("::::::aaa\n::>>bb\n"));
        $self->assert_equals(
		"<div><div><div>aaa\n</div></div></div><blockquote>bb\n</blockquote>",
		$self->wiki2Html("::::::aaa\n>>bb\n"));
        $self->assert_equals(
		"<div><div><div>aaa\n</div></div>bb\n</div>",
		$self->wiki2Html("::::::aaa\n::bb\n"));

}
sub test_ko_classed_mixed_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div class=\"aClass\">aaa\n{bClass}bbb\n</div>\n",
		$self->wiki2Html("::{aClass}aaa\n::{bClass}bbb\n\n"));
        $self->assert_equals(
		"<blockquote>aaa\n{aClass}bbb\n</blockquote>\n",
		$self->wiki2Html(">>aaa\n>>{aClass}bbb\n\n"));
        $self->assert_equals(
		"<div><div><div>aaa\n</div></div>{quote}bb\n</div>",
		$self->wiki2Html("::::::aaa\n::{quote}bb\n"));
}
sub test_ok_nested_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div><div>aaa\n</div></div>",
		$self->wiki2Html("::::aaa\n"));
        $self->assert_equals(
		"<div>aaa\n<div>bb</div></div>",
		$self->wiki2Html("::aaa\n::::bb"));
}
sub test_ko_multiline_images {
        my$self=shift;
        $self->assert_equals(
		"&lt;&lt;/a\n<blockquote></blockquote>",
		$self->wiki2Html("<</a\n>>"));
        $self->assert_equals(
		"&lt;&lt;{x}/a a <em>d d</em>\n<blockquote></blockquote>",
		$self->wiki2Html("<<{x}/a a //d d//\n>>"));
}

sub test_ok_multiline_headers {
        my$self=shift;
        $self->assert_equals(
		"<h1>head\n1</h1>",
		$self->wiki2Html("== head\n1 =="));
        $self->assert_equals(
		"<h2>head\n2</h2>",
		$self->wiki2Html("=== head\n2 ==="));
        $self->assert_equals(
		"<h2>head\n2</h2>",
		$self->wiki2Html("=== head\n2 =="));
        $self->assert_equals(
		"<h2>head\n2</h2>",
		$self->wiki2Html("=== head\n2 ===="));
        $self->assert_equals(
		"<h2>head\n2</h2>",
		$self->wiki2Html("=== head\n    2 ==="));
	$self->assert_equals(
		"<h2>a <em>em\nhead</em> 2</h2>",
		$self->wiki2Html("=== a //em\nhead// 2 ==="));
        $self->assert_equals(
		"<p>head\n10</p>",
		$self->wiki2Html("=========== head\n10 ==========="));
}
sub test_ko_multiline_headers {
        my$self=shift;
        $self->assert_equals(
		"== head\n\n1 ==",
		$self->wiki2Html("== head\n\n1 =="));
        $self->assert_equals(
		"=== head\n\n2 ===",
		$self->wiki2Html("=== head\n\n2 ==="));
        $self->assert_equals(
		"=== head\n2 =====",
		$self->wiki2Html("=== head\n2 ====="));
        $self->assert_equals(
		"==== head\n3 ==",
		$self->wiki2Html("==== head\n3 =="));
        $self->assert_equals(
		"============ head\n11 ============",
		$self->wiki2Html("============ head\n11 ============"));
        $self->assert_equals(
		"<table><tbody><tr><td>** head\n2 ===</td></tr></tbody></table>",
		$self->wiki2Html("||** head\n||2 ==="));
}


sub tear_down {
    # clean up after test
}

1;
