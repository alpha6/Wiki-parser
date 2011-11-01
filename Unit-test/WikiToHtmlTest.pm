#!/usr/bin/perl
package Wiki2HtmlTest;

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
	$xInWiki->line($IN);
	$xInWiki->flush();
        return$OUT;
}

sub wikiArray2Html{
	my$self=shift;
	my$IN=shift;
        my$baseConfig=$self->{'baseConfig'};
        my$OUT='';
	my$out=xPeerlIo::xOutXhtml->new($baseConfig,sub{$OUT.=$_[0]});
        my$xInWiki=xPeerlIo::xInWiki->new($baseConfig,$out);
	foreach(@{$IN}){
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
		'pixelUrl'=>'/px.gif',
	};
}
sub test_ok_simple_inline {
# простые тесты для строчного форматирования
# цель - проверить поддержку __ВСЕХ__ строчных команд
        my$self=shift;
        $self->assert_equals("<em>aaa</em>",$self->wiki2Html("//aaa//"));
        $self->assert_equals("<strong>bbb</strong>",$self->wiki2Html("**bbb**"));
        $self->assert_equals("<del>aaa</del>",$self->wiki2Html("--aaa--"));
        $self->assert_equals("<ins>bbb</ins>",$self->wiki2Html("++bbb++"));
        $self->assert_equals("<cite>ccc</cite>",$self->wiki2Html("''ccc''"));
        $self->assert_equals("<tt>aaa</tt>",$self->wiki2Html("##aaa##"));
        $self->assert_equals("<u>bbb</u>",$self->wiki2Html("__bbb__"));
        $self->assert_equals("<sup>aaa</sup>",$self->wiki2Html("^^aaa^^"));
        $self->assert_equals("<sub>bbb</sub>",$self->wiki2Html("vvbbbvv"));
}
sub test_bad_simple_inline {
# простые тесты для строчного форматирования
# цель - проверить что ошибочные команды не конвертируются
        my$self=shift;
        $self->assert_equals("//aaa //",$self->wiki2Html("//aaa //"));
        $self->assert_equals("//  aaa//",$self->wiki2Html("//  aaa//"));
        $self->assert_equals("// aaa //",$self->wiki2Html("// aaa //"));
        $self->assert_equals("//aaa //aaa",$self->wiki2Html("//aaa //aaa"));
	$self->assert_equals("** a//**++",$self->wiki2Html("** a//**++"));

}
sub test_ok_simple_classes_inline {
# простые тесты для строчного форматирования с классами
# цель - проверить поддержку классов
        my$self=shift;
        $self->assert_equals("<em class=\"aClass\">aaa</em>",$self->wiki2Html("//{aClass}aaa//"));
        $self->assert_equals("<del class=\"bClass\">aaa</del>",$self->wiki2Html("--{bClass}aaa--"));
        $self->assert_equals("<em class=\"aClass\"> aaa</em>",$self->wiki2Html("//{aClass} aaa//"));
        $self->assert_equals("// {aClass}aaa//",$self->wiki2Html("// {aClass}aaa//"));
}

sub test_ok_nested_inline {
        my$self=shift;
        $self->assert_equals(
		"<em>a <strong>b c</strong> aa</em>",
		$self->wiki2Html("//a **b c** aa//"));
}
sub test_bad_nested_inline {
        my$self=shift;
        $self->assert_equals(
		"// a <strong>b c</strong> aa//",
		$self->wiki2Html("// a **b c** aa//"));
        $self->assert_equals(
		"<em>a ** b c** aa</em>",
		$self->wiki2Html("//a ** b c** aa//"));
        $self->assert_equals(
		"<em>a **b __c --sss ** aa</em>",
		$self->wiki2Html("//a **b __c --sss ** aa//"));
}

sub test_ok_simple_links {
        my$self=shift;
        $self->assert_equals(
		"<a href=\"aaa\">aaa</a>",
		$self->wiki2Html("[[aaa]]"));
        $self->assert_equals(
		"<a href=\"aaa\" class=\"link\">aaa</a>",
		$self->wiki2Html("[[{link}aaa]]"));
        $self->assert_equals(
		"<a href=\"aaa\" class=\"link\">bbb</a>",
		$self->wiki2Html("[[{link}aaa bbb]]"));
        $self->assert_equals(
		"<a href=\"aaa\" target=\"left\">aaa</a>",
		$self->wiki2Html("[[{^left}aaa]]"));
        $self->assert_equals(
		"<a href=\"aaa\" target=\"left\" class=\"link\">aaa</a>",
		$self->wiki2Html("[[{^left link}aaa]]"));
}

sub test_bad_simple_links {
        my$self=shift;
        $self->assert_equals(
		"[[aaa[[",
		$self->wiki2Html("[[aaa[["));
        $self->assert_equals(
		"[[ aaa]]",
		$self->wiki2Html("[[ aaa]]"));
        $self->assert_equals(
		"[[aaa ]]",
		$self->wiki2Html("[[aaa ]]"));
        $self->assert_equals(
		"[[ aaa ]]",
		$self->wiki2Html("[[ aaa ]]"));
        $self->assert_equals(
		"[[  aaa bbb]]",
		$self->wiki2Html("[[  aaa bbb]]"));
        $self->assert_equals(
		"[[aaa  bbb  ]]",
		$self->wiki2Html("[[aaa  bbb  ]]"));
        $self->assert_equals(
		"[[ aaa bbb ]]",
		$self->wiki2Html("[[ aaa bbb ]]"));
        $self->assert_equals(
		"<a class=\"link\"> aaa</a>",
		$self->wiki2Html("[[{link} aaa]]"));
        $self->assert_equals(
		"<a class=\"link\"> aaa bbb</a>",
		$self->wiki2Html("[[{link} aaa bbb]]"));
        $self->assert_equals(
		"<a href=\"{\">link}aaa bbb</a>",
		$self->wiki2Html("[[{ link}aaa bbb]]"));
        $self->assert_equals(
		"<a href=\"{link\">}aaa bbb</a>",
		$self->wiki2Html("[[{link }aaa bbb]]"));
        $self->assert_equals(
		"<a href=\"{\">^left link}aaa</a>",
		$self->wiki2Html("[[{ ^left link}aaa]]"));
        $self->assert_equals(
		"<a href=\"{^\">left link}aaa</a>",
		$self->wiki2Html("[[{^ left link}aaa]]"));
        $self->assert_equals(
		"<a href=\"{link^left}aaa\">{link^left}aaa</a>",
		$self->wiki2Html("[[{link^left}aaa]]"));
    }
sub test_ok_simple_images {
        my$self=shift;
        $self->assert_equals(
		"<img src=\"/a\" alt=\"\"/>",
		$self->wiki2Html("<</a>>"));
        $self->assert_equals(
		"<img src=\"/a\" alt=\"\" class=\"x\"/>",
		$self->wiki2Html("<<{x}/a>>"));
        $self->assert_equals(
		"<img src=\"/a\" alt=\"\" align=\"x\"/>",
		$self->wiki2Html("<<{^x}/a>>"));
        $self->assert_equals(
		"<img src=\"/a\" alt=\"\" align=\"x\" class=\"y\"/>",
		$self->wiki2Html("<<{^x y}/a>>"));
        $self->assert_equals(
		"<img src=\"/a\" alt=\"b\" class=\"x\" title=\"b\"/>",
		$self->wiki2Html("<<{x}/a b>>"));
        $self->assert_equals(
		"<img src=\"{\" alt=\"\"/>",
		$self->wiki2Html("<<{>>"));
        $self->assert_equals(
		"<img src=\"/px.gif\" alt=\"/a\" class=\"x\" title=\"/a\"/>",
		$self->wiki2Html("<<{x} /a>>"));
}
sub test_ko_simple_images {
        my$self=shift;
        $self->assert_equals(
		"&lt;&lt; /a&gt;&gt;",
		$self->wiki2Html("<< /a>>"));
        $self->assert_equals(
		"&lt;&lt;{x}/a a <em>d d</em> &gt;",
		$self->wiki2Html("<<{x}/a a //d d// >"));
}

sub test_ok_nested_links {
        my$self=shift;
        $self->assert_equals(
		"<a href=\"aaa\"><em>aa<u>tx</u>a</em></a>",
		$self->wiki2Html("[[aaa //aa__tx__a//]]"));
        $self->assert_equals(
		"<a href=\"aaa\" target=\"left\" class=\"link\"><em>aa<u>tx</u>a</em></a>",
		$self->wiki2Html("[[{^left link}aaa //aa__tx__a//]]"));
}

sub test_ok_simply_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div>aaa</div>",
		$self->wiki2Html("::aaa"));
        $self->assert_equals(
		"<blockquote>bbb</blockquote>",
		$self->wiki2Html(">>bbb"));
        $self->assert_equals(
		"<div class=\"bClass\">aaa</div>",
		$self->wiki2Html("::{bClass}aaa"));
        $self->assert_equals(
		"<blockquote class=\"aClass\">bbb</blockquote>",
		$self->wiki2Html(">>{aClass}bbb"));
}
sub test_ok_headers {
        my$self=shift;
        $self->assert_equals(
		"<h1>head 1</h1>",
		$self->wiki2Html("== head 1 =="));
	$self->assert_equals(
		"<h1>head 1</h1>",
		$self->wiki2Html("== head 1 ==="));
        $self->assert_equals(
		"<h2>head 2</h2>",
		$self->wiki2Html("=== head 2 ==="));
        $self->assert_equals(
		"<h2>head 2</h2>",
		$self->wiki2Html("=== head 2 =="));
        $self->assert_equals(
		"<h3>head 3</h3>",
		$self->wiki2Html("==== head 3 ===="));
        $self->assert_equals(
		"<h4>head 4</h4>",
		$self->wiki2Html("===== head 4 ====="));
        $self->assert_equals(
		"<h5>head 5</h5>",
		$self->wiki2Html("====== head 5 ======"));
        $self->assert_equals(
		"<h6>head 6</h6>",
		$self->wiki2Html("======= head 6 ======="));
        $self->assert_equals(
		"<h6>head 7</h6>",
		$self->wiki2Html("======== head 7 ========"));
        $self->assert_equals(
		"<p>head 8</p>",
		$self->wiki2Html("========= head 8 ========="));
        $self->assert_equals(
		"<p>head 9</p>",
		$self->wiki2Html("========== head 9 =========="));
        $self->assert_equals(
		"<p>head 10</p>",
		$self->wiki2Html("=========== head 10 ==========="));
}
sub test_ko_headers {
        my$self=shift;
        $self->assert_equals(
		"== head 1 ====",
		$self->wiki2Html("== head 1 ===="));
        $self->assert_equals(
		"===== head 4 ===",
		$self->wiki2Html("===== head 4 ==="));
        $self->assert_equals(
		"============ head 10 ============",
		$self->wiki2Html("============ head 10 ============"));
}
sub test_ok_styled_headers {
        my$self=shift;
        $self->assert_equals(
		"<h1 class=\"a\">head 1</h1>",
		$self->wiki2Html("=={a} head 1 =="));
        $self->assert_equals(
		"<h1 class=\"a\">head\n1</h1>",
		$self->wiki2Html("=={a} head\n1 =="));
}
sub test_ko_styled_headers {
        my$self=shift;
        $self->assert_equals(
		"=={a}head 1 ==",
		$self->wiki2Html("=={a}head 1 =="));
        $self->assert_equals(
		"=={a head 1 ==",
		$self->wiki2Html("=={a head 1 =="));
        $self->assert_equals(
		"=={a-a} head 1 ==",
		$self->wiki2Html("=={a-a} head 1 =="));
        $self->assert_equals(
		"<h1>{a} head 1</h1>",
		$self->wiki2Html("== {a} head 1 =="));
}
sub test_ok_nested_blocks {
        my$self=shift;
        $self->assert_equals(
		"<div><div>aaa</div></div>",
		$self->wiki2Html("::::aaa"));
        $self->assert_equals(
		"<div><blockquote><div>abc</div></blockquote></div>",
		$self->wiki2Html("::>>::abc"));
        $self->assert_equals(
		"<div class=\"a\"><blockquote class=\"b\"><div class=\"c\">abc</div></blockquote></div>",
		$self->wiki2Html("::{a}>>{b}::{c}abc"));
}
sub test_ok_no_cr {
        my$self=shift;
        $self->assert_equals("<em>ab</em>",
		$self->wikiArray2Html(["//a","b//"]));
        $self->assert_equals("//ab//",
		$self->wikiArray2Html(["//a","","b//"]));
        $self->assert_equals(
		"<div>aaa</div><div>aaa</div>",
		$self->wikiArray2Html(["::aaa","","::aaa"]));
        $self->assert_equals(
		"<div>aaaaaa</div>",
		$self->wikiArray2Html(["::aaa","::aaa"]));
}


sub tear_down {
    # clean up after test
}

1;
