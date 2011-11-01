#!/usr/bin/perl
package Wiki2HtmlTableTest;

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
sub test_ok_simple_table {
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td>a</td></tr></tbody></table>",$self->wiki2Html("|| a ||"));
        $self->assert_equals("<table><tbody><tr><td>a</td></tr></tbody></table>",$self->wiki2Html("||a||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>b</td><td>c</td></tr></tbody></table>",$self->wiki2Html("|| a || b || c ||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>b</td></tr>\n"
	    ."<tr><td>c</td><td>d</td></tr></tbody></table>",$self->wiki2Html("|| a || b ||\n|| c || d ||"));
}
sub test_ok_inline_in_table {
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td><em>a</em></td></tr></tbody></table>",$self->wiki2Html("|| //a// ||"));
        $self->assert_equals("<table><tbody><tr><td>//a</td></tr></tbody></table>",$self->wiki2Html("||//a||"));
        $self->assert_equals("<table><tbody><tr><td>a//</td></tr></tbody></table>",$self->wiki2Html("|| a//||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td><em>b</em></td></tr></tbody></table>",$self->wiki2Html("||a||//b//||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>// b//</td></tr></tbody></table>",$self->wiki2Html("||a||// b//||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>//b //</td></tr></tbody></table>",$self->wiki2Html("||a||//b //||"));
        $self->assert_equals("<table><tbody><tr><td>//a</td><td>b//</td></tr></tbody></table>",$self->wiki2Html("||//a||b//||"));
}
sub test_ok_multiline_table {
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td>a</td></tr></tbody></table>",$self->wiki2Html("||a"));
        $self->assert_equals("<table><tbody><tr><td>a</td></tr></tbody></table>",$self->wiki2Html("|| a"));
        $self->assert_equals("<table><tbody><tr><td>a\nb\nc</td></tr></tbody></table>",$self->wiki2Html("|| a\n||b \n||c"));
        $self->assert_equals("<table><tbody><tr><td>a\nb\nc</td></tr></tbody></table>",$self->wiki2Html("|| a\n||b \n||c||"));
}
sub test_ko_simple_table {
        my$self=shift;
        $self->assert_equals("a ||",$self->wiki2Html(" a ||"));
        $self->assert_equals("a||",$self->wiki2Html(" a||"));
        $self->assert_equals("a ||b",$self->wiki2Html(" a ||b"));
        $self->assert_equals("a || b ",$self->wiki2Html(" a || b "));
        $self->assert_equals("a || b ||",$self->wiki2Html(" a || b ||"));
        $self->assert_equals("a || b ||c",$self->wiki2Html(" a || b ||c"));
}
sub test_ok_header_table {
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><th>a</th><th>b</th></tr></tbody></table>",$self->wiki2Html("||** a **||** b **||"));
        $self->assert_equals("<table><tbody><tr><th>a</th></tr>\n<tr><th>b</th></tr></tbody></table>",$self->wiki2Html("||** a **||\n||** b **||"));
        $self->assert_equals("<table><tbody><tr><th><em>a</em></th><th><em>b</em></th></tr></tbody></table>",$self->wiki2Html("||** //a// **||** //b// **||"));
}
sub test_ko_header_table {
        my$self=shift;
        $self->assert_equals("a **||",$self->wiki2Html(" a **||"));
        $self->assert_equals("a**||",$self->wiki2Html(" a**||"));
        $self->assert_equals("a<strong>||</strong>",$self->wiki2Html(" a**||**"));
        $self->assert_equals("a ||b",$self->wiki2Html(" a ||b"));
        $self->assert_equals("a || b ",$self->wiki2Html(" a || b "));
        $self->assert_equals("a || b ||",$self->wiki2Html(" a || b ||"));
        $self->assert_equals("a || b ||c",$self->wiki2Html(" a || b ||c"));
}
sub test_ko_table_header_detection {
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td>a**</td><td>b**</td></tr></tbody></table>",$self->wiki2Html("||a**||b**||"));
        $self->assert_equals("<table><tbody><tr><td>** a</td><td>** b</td></tr></tbody></table>",$self->wiki2Html("||** a||** b||"));
        $self->assert_equals("<table><tbody><tr><td>a**</td><td>b**</td></tr></tbody></table>",$self->wiki2Html("|| a**|| b**||"));
        $self->assert_equals("<table><tbody><tr><td>** a**</td><td>** b**</td></tr></tbody></table>",$self->wiki2Html("||** a**||** b**||"));
        $self->assert_equals("<table><tbody><tr><td>** a<em>a</em>a**</td><td>** b<em>b</em>b**</td></tr></tbody></table>",$self->wiki2Html("||** a//a//a**||** b//b//b**||"));

        $self->assert_equals("<table><tbody><tr><td>** a</td><td>** b</td></tr></tbody></table>",$self->wiki2Html("||** a||** b||"));
        $self->assert_equals("<table><tbody><tr><td>a **</td><td>b **</td></tr></tbody></table>",$self->wiki2Html("||a **||b **||"));
        $self->assert_equals("<table><tbody><tr><td>**a **</td></tr></tbody></table>",$self->wiki2Html("||**a **||"));
        $self->assert_equals("<table><tbody><tr><td>**a **</td><td>**b **</td></tr></tbody></table>",$self->wiki2Html("||**a **||**b **||"));
        $self->assert_equals("<table><tbody><tr><td>** a</td></tr></tbody></table>",$self->wiki2Html("||** a"));
}
sub test_ok_styled_headers_in_table {
        my$self=shift;
        $self->assert_equals(
		"<table><tbody><tr><td><h1 class=\"a\">head 1</h1></td></tr></tbody></table>",
		$self->wiki2Html("||=={a} head 1 ==||"));
        $self->assert_equals(
		"<table><tbody><tr><td>a</td><td><h2 class=\"b\">head 2</h2></td></tr></tbody></table>",
		$self->wiki2Html("||a||==={b} head 2 ===||"));
        $self->assert_equals(
		"<table><tbody><tr><td><h1 class=\"a\">head\n1</h1></td></tr></tbody></table>",
		$self->wiki2Html("||=={a} head\n||1 =="));
}
sub test_ko_styled_headers_in_table {
        my$self=shift;
        $self->assert_equals(
		"<table><tbody><tr><td>=={a}head 1 ==</td></tr></tbody></table>",
		$self->wiki2Html("||=={a}head 1 ==||"));
        $self->assert_equals(
		"<table><tbody><tr><td>=={a head 1 ==</td></tr></tbody></table>",
		$self->wiki2Html("||=={a head 1 ==||"));
        $self->assert_equals(
		"<table><tbody><tr><td>=={2+2} head 1 ==</td></tr></tbody></table>",
		$self->wiki2Html("||=={2+2} head 1 ==||"));
        $self->assert_equals(
		"<table><tbody><tr><td><h1>{a} head 1</h1></td></tr></tbody></table>",
		$self->wiki2Html("||== {a} head 1 ==||"));



        $self->assert_equals(
		"<table><tbody><tr><td>a</td><td>==={b}head 2 ===</td></tr></tbody></table>",
		$self->wiki2Html("||a||==={b}head 2 ===||"));
        $self->assert_equals(
		"<table><tbody><tr><td>a</td><td>==={b head 2 ===</td></tr></tbody></table>",
		$self->wiki2Html("||a||==={b head 2 ===||"));
        $self->assert_equals(
		"<table><tbody><tr><td>a</td><td>==={2*2} head 2 ===</td></tr></tbody></table>",
		$self->wiki2Html("||a||==={2*2} head 2 ===||"));
        $self->assert_equals(
		"<table><tbody><tr><td>a</td><td><h2>{b} head 2</h2></td></tr></tbody></table>",
		$self->wiki2Html("||a||=== {b} head 2 ===||"));
        $self->assert_equals(
		"<table><tbody><tr><td>=={a}head\n1 ==</td></tr></tbody></table>",
		$self->wiki2Html("||=={a}head\n||1 =="));
        $self->assert_equals(
		"<table><tbody><tr><td>=={a head\n1 ==</td></tr></tbody></table>",
		$self->wiki2Html("||=={a head\n||1 =="));
        $self->assert_equals(
		"<table><tbody><tr><td>=={2+2} head\n1 ==</td></tr></tbody></table>",
		$self->wiki2Html("||=={2+2} head\n||1 =="));
        $self->assert_equals(
		"<table><tbody><tr><td><h1>{a} head\n1</h1></td></tr></tbody></table>",
		$self->wiki2Html("||== {a} head\n||1 =="));
}

sub test_ok_styled_cell_table {
# простые тесты для списков
# цель - проверить поддержку стилей и стартовых значений типов списков
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td class=\"cls\">a</td><td class=\"cls2\">b</td></tr></tbody></table>",$self->wiki2Html("||{cls} a ||{cls2}b||"));
        $self->assert_equals("<table><tbody><tr><td colspan=\"2\" rowspan=\"2\" class=\"cls\">a</td><td colspan=\"3\" rowspan=\"3\" class=\"cls2\">b</td></tr></tbody></table>",$self->wiki2Html("||{2*2 cls} a ||{3*3 cls2}b||"));
        $self->assert_equals("<table><tbody><tr><td colspan=\"2\" rowspan=\"2\">a</td><td colspan=\"3\" rowspan=\"3\">b</td></tr></tbody></table>",$self->wiki2Html("||{2*2} a ||{3*3}b||"));
}
sub test_ko_styled_cell_table {
# простые тесты для списков
# цель - проверить поддержку стилей и стартовых значений типов списков
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td>{cls } a</td><td>{ cls2}b</td></tr></tbody></table>",$self->wiki2Html("||{cls } a ||{ cls2}b||"));
        $self->assert_equals("<table><tbody><tr><td>{cls} a</td><td>{ cls2 }b</td></tr></tbody></table>",$self->wiki2Html("|| {cls} a ||{ cls2 }b||"));
        $self->assert_equals("<table><tbody><tr><td>{2*2cls} a</td><td>{ 3*3 cls}b</td></tr></tbody></table>",$self->wiki2Html("||{2*2cls} a ||{ 3*3 cls}b||"));
}
sub test_ok_styled_header_cell_table {
# простые тесты для списков
# цель - проверить поддержку стилей и стартовых значений типов списков
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><th class=\"cls\">a</th><th class=\"cls2\">b</th></tr></tbody></table>",$self->wiki2Html("||{cls}** a **||{cls2}** b **||"));
        $self->assert_equals("<table><tbody><tr><th colspan=\"2\" rowspan=\"2\" class=\"cls\">a</th><th colspan=\"3\" rowspan=\"3\" class=\"cls2\">b</th></tr></tbody></table>",$self->wiki2Html("||{2*2 cls}** a **||{3*3 cls2}** b **||"));
        $self->assert_equals("<table><tbody><tr><th colspan=\"2\" rowspan=\"2\">a</th><th colspan=\"3\" rowspan=\"3\">b</th></tr></tbody></table>",$self->wiki2Html("||{2*2}** a **||{3*3}** b **||"));
}
sub test_ko_styled_header_cell_table {
# простые тесты для списков
# цель - проверить поддержку стилей и стартовых значений типов списков
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td colspan=\"2\" rowspan=\"2\">** a **</td><td colspan=\"3\" rowspan=\"3\">** b **</td></tr></tbody></table>",$self->wiki2Html("||{2*2} ** a **||{3*3} ** b **||"));
        $self->assert_equals("<table><tbody><tr><td colspan=\"2\" rowspan=\"2\">** a **</td><td colspan=\"3\" rowspan=\"3\">** b **</td></tr></tbody></table>",$self->wiki2Html("||{2*2}** a ** ||{3*3}** b ** ||"));
        $self->assert_equals("<table><tbody><tr><td colspan=\"2\" rowspan=\"2\">** a</td><td colspan=\"3\" rowspan=\"3\">** b</td></tr></tbody></table>",$self->wiki2Html("||{2*2}** a||{3*3}** b||"));
}
sub test_ok_nested_table {
# простые тесты для списков
# цель - проверить обработку вложенных списков
        my$self=shift;

        $self->assert_equals("<table><tbody><tr><td>a\n<table><tbody><tr><td>b</td></tr>\n</tbody></table></td></tr></tbody></table>",$self->wiki2Html("||a\n||||b||\n"));
        $self->assert_equals("<table><tbody><tr><td>a\n<table><tbody><tr><td>b\n</td></tr></tbody></table></td></tr></tbody></table>",$self->wiki2Html("||a\n||||b\n"));
}
sub test_ko_nested_table {
# простые тесты для списков
# цель - проверить обработку вложенных списков
        my$self=shift;
        $self->assert_equals("<div>aaa ||</div>",$self->wiki2Html(":: aaa ||"));
}
sub test_ok_lists_in_table {
        my$self=shift;
        $self->assert_equals("<table><tbody><tr><td><ol type=\"a\"><li>aaa</li></ol></td></tr></tbody></table>",$self->wiki2Html("||  a. aaa ||"));

}

sub test_ko_header_in_table_detection {
        my$self=shift;

        $self->assert_equals("<table><tbody><tr><td>==== AAA **</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||==== AAA **|| a ||"));

        $self->assert_equals("<table><tbody><tr><td><h1>AAA</h1></td><td><h2>nnn</h2></td></tr></tbody></table>",$self->wiki2Html("||== AAA ==||=== nnn ===||"));

        $self->assert_equals("<table><tbody><tr><td>** AAA ==</td></tr></tbody></table>",$self->wiki2Html("||** AAA =="));
        $self->assert_equals("<table><tbody><tr><td>=== AAA **</td></tr></tbody></table>",$self->wiki2Html("||=== AAA **"));
        $self->assert_equals("<table><tbody><tr><td>AAA ==</td></tr></tbody></table>",$self->wiki2Html("|| AAA =="));
        $self->assert_equals("<table><tbody><tr><td>=== AAA</td></tr></tbody></table>",$self->wiki2Html("||=== AAA"));

        $self->assert_equals("<table><tbody><tr><td>== AAA==</td></tr></tbody></table>",$self->wiki2Html("||== AAA=="));
        $self->assert_equals("<table><tbody><tr><td>==AAA ==</td></tr></tbody></table>",$self->wiki2Html("||==AAA =="));
        $self->assert_equals("<table><tbody><tr><td>==AAA==</td></tr></tbody></table>",$self->wiki2Html("||==AAA=="));


        $self->assert_equals("<table><tbody><tr><td>** AAA ==</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||** AAA ==|| a ||"));
        $self->assert_equals("<table><tbody><tr><td>==== AAA **</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||==== AAA **|| a ||"));
        $self->assert_equals("<table><tbody><tr><td>AAA ==</td><td>a</td></tr></tbody></table>",$self->wiki2Html("|| AAA ==|| a ||"));
        $self->assert_equals("<table><tbody><tr><td>==== AAA</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||==== AAA || a ||"));
        $self->assert_equals("<table><tbody><tr><td>=== AAA===</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||=== AAA===|| a ||"));
        $self->assert_equals("<table><tbody><tr><td>===AAA ===</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||===AAA ===|| a ||"));
        $self->assert_equals("<table><tbody><tr><td>===AAA===</td><td>a</td></tr></tbody></table>",$self->wiki2Html("||===AAA===|| a ||"));

        $self->assert_equals("<table><tbody><tr><td>a</td><td>** AAA ==</td></tr></tbody></table>",$self->wiki2Html("|| a ||** AAA ==||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==== AAA **</td></tr></tbody></table>",$self->wiki2Html("|| a ||==== AAA **||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>AAA ==</td></tr></tbody></table>",$self->wiki2Html("|| a || AAA ==||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==== AAA</td></tr></tbody></table>",$self->wiki2Html("|| a ||==== AAA ||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==== AAA====</td></tr></tbody></table>",$self->wiki2Html("|| a ||==== AAA====||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>====AAA ====</td></tr></tbody></table>",$self->wiki2Html("|| a ||====AAA ====||"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>====AAA====</td></tr></tbody></table>",$self->wiki2Html("|| a ||====AAA====||"));

}

sub test_ko_header_in_multiline_table_detection {
        my$self=shift;

        $self->assert_equals("<table><tbody><tr><td>** AAA ==\naa</td></tr></tbody></table>",$self->wiki2Html("||** AAA ==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>==== AAA **\naa</td></tr></tbody></table>",$self->wiki2Html("||==== AAA **\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>AAA ==\naa</td></tr></tbody></table>",$self->wiki2Html("|| AAA ==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>==== AAA\naa</td></tr></tbody></table>",$self->wiki2Html("||==== AAA \n||aa"));
        $self->assert_equals("<table><tbody><tr><td>== AAA==\naa</td></tr></tbody></table>",$self->wiki2Html("||== AAA==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>==AAA ==\naa</td></tr></tbody></table>",$self->wiki2Html("||==AAA ==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>==AAA==\naa</td></tr></tbody></table>",$self->wiki2Html("||==AAA==\n||aa"));

        $self->assert_equals("<table><tbody><tr><td>a</td><td>** AAA ==\naa</td></tr></tbody></table>",$self->wiki2Html("|| a ||** AAA ==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==== AAA **\naa</td></tr></tbody></table>",$self->wiki2Html("|| a ||==== AAA **\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>AAA ==\naa</td></tr></tbody></table>",$self->wiki2Html("|| a || AAA ==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==== AAA\naa</td></tr></tbody></table>",$self->wiki2Html("|| a ||==== AAA \n||aa"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>== AAA==\naa</td></tr></tbody></table>",$self->wiki2Html("|| a ||== AAA==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==AAA ==\naa</td></tr></tbody></table>",$self->wiki2Html("|| a ||==AAA ==\n||aa"));
        $self->assert_equals("<table><tbody><tr><td>a</td><td>==AAA==\naa</td></tr></tbody></table>",$self->wiki2Html("|| a ||==AAA==\n||aa"));

}
sub test_ok_header_in_table_detection {
        my$self=shift;

        $self->assert_equals("<table><tbody><tr><td>\n<h1>AAA\na\n</h1>b</td></tr></tbody></table>",$self->wiki2Html("||\n||== AAA\n||a ==\n|| b"));

        $self->assert_equals("<table><tbody><tr><td><h1>AAA</h1></td><td><h2>b\n</h2></td></tr></tbody></table>",$self->wiki2Html("||== AAA ==||=== b ===\n"));

        $self->assert_equals("<table><tbody><tr><td><h1>AAA</h1></td><td><h2>a</h2></td><td><h3>b</h3></td></tr></tbody></table>",$self->wiki2Html("||== AAA ==||=== a ===||==== b ====||"));
        $self->assert_equals("<table><tbody><tr><td><h1>AAA\n</h1><h2>a</h2></td><td><h3>b</h3></td></tr></tbody></table>",$self->wiki2Html("||== AAA ==\n||=== a ===||==== b ====||"));
        $self->assert_equals("<table><tbody><tr><td><h1>AAA</h1></td></tr>\n</tbody></table>",$self->wiki2Html("||== AAA ==||\n"));

}


sub tear_down {
    # clean up after test
}

1;
