#!/usr/bin/perl
package Wiki2HtmlListTest;

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
sub test_ok_simple_list {
# простые тесты для списков
# цель - проверить поддержку __ВСЕХ__ типов списков
        my$self=shift;
        $self->assert_equals("<ul><li>aaa</li></ul>",$self->wiki2Html("  * aaa"));
        $self->assert_equals("<ul><li>aaa\n</li></ul>",$self->wiki2Html("  * aaa\n"));
        $self->assert_equals("<ul><li>aaa\n</li><li>bbb</li></ul>",$self->wiki2Html("  * aaa\n  * bbb"));
        $self->assert_equals("<ul><li>aaa\n</li><li>bbb\n</li></ul>",$self->wiki2Html("  * aaa\n  * bbb\n"));
        $self->assert_equals("<ol><li>aaa</li></ol>",$self->wiki2Html("  1. aaa"));
        $self->assert_equals("<ol><li>aaa\n</li></ol>",$self->wiki2Html("  1. aaa\n"));
        $self->assert_equals("<ol><li>aaa\n</li><li>bbb</li></ol>",$self->wiki2Html("  1. aaa\n  2. bbb"));
        $self->assert_equals("<ol><li>aaa\n</li><li>bbb\n</li></ol>",$self->wiki2Html("  2. aaa\n  1. bbb\n"));
}
sub test_ok_styled_list {
# простые тесты для списков
# цель - проверить поддержку стилей и стартовых значений типов списков
        my$self=shift;
        $self->assert_equals("<ul class=\"x\"><li>aaa</li></ul>",$self->wiki2Html("  {x}* aaa"));
        $self->assert_equals("<ul><li class=\"y\">aaa</li></ul>",$self->wiki2Html("  *{y} aaa"));
        $self->assert_equals("<ol class=\"x\"><li>aaa</li></ol>",$self->wiki2Html("  {x}1. aaa"));
        $self->assert_equals("<ol><li class=\"y\">aaa</li></ol>",$self->wiki2Html("  1.{y} aaa"));
        $self->assert_equals("<ol class=\"x\" type=\"a\"><li>aaa</li></ol>",$self->wiki2Html("  {x}a. aaa"));
        $self->assert_equals("<ol type=\"A\"><li class=\"y\">aaa</li></ol>",$self->wiki2Html("  A.{y} aaa"));
        $self->assert_equals("<ol start=\"12\"><li>aaa</li></ol>",$self->wiki2Html("  1.#12 aaa"));

}
sub test_ko_simple_list {
# простые тесты для списков
# цель - проверить обработку ошибок форматирования списков
        my$self=shift;
        $self->assert_equals("* aaa",$self->wiki2Html("* aaa"));
        $self->assert_equals("* aaa",$self->wiki2Html(" * aaa"));
        $self->assert_equals("*aaa",$self->wiki2Html("  *aaa"));
        $self->assert_equals("1. aaa",$self->wiki2Html("1. aaa"));
        $self->assert_equals("1. aaa",$self->wiki2Html(" 1. aaa"));
        $self->assert_equals("1.aaa",$self->wiki2Html("  1.aaa"));
        $self->assert_equals("1 aaa",$self->wiki2Html("  1 aaa"));
}
sub test_ok_nested_list {
# простые тесты для списков
# цель - проверить обработку вложенных списков
        my$self=shift;

        $self->assert_equals("<ul><li>aaa\n</li></ul>a",
		$self->wiki2Html("  * aaa\n"
		                ."a"));
        $self->assert_equals("<ul><li>aaa\nbbb</li></ul>",
		$self->wiki2Html("  * aaa\n"
		                ."  bbb"));
        $self->assert_equals("<ol><li>aaa\n</li></ol><ul><li>bbb</li></ul>",
		$self->wiki2Html("  1. aaa\n"
		                ."  * bbb"));
        $self->assert_equals("<ul><li>aaa\n<ul><li>bbb</li></ul></li></ul>",
		$self->wiki2Html("  * aaa\n"
		                ."    * bbb"));

        $self->assert_equals("<ul><li>aaa\nbbb\n</li></ul>a",
		$self->wiki2Html("  * aaa\n"
		                ."  bbb\n"
		                ."a"));
        $self->assert_equals("<ul><li>aaa\n<br/>bbb\n</li></ul>a",
		$self->wiki2Html("  * aaa\n"
		                ."    bbb\n"
		                ."a"));
}
sub test_ok_restart_nested_list {
# простые тесты для списков
# цель - проверить обработку вложенных списков
        my$self=shift;

        $self->assert_equals("<ul><li>aaa\n</li></ul><ul class=\"b\"><li>aaa</li></ul>",
		$self->wiki2Html("  * aaa\n"
		                ."  {b}* aaa"));
        $self->assert_equals("<ul><li>aaa\n</li></ul><ol><li>bbb</li></ol>",
		$self->wiki2Html("  * aaa\n"
		                ."  1. bbb"));
        $self->assert_equals("<ol><li>aaa\n</li></ol><ol start=\"2\"><li>bbb</li></ol>",
		$self->wiki2Html("  1. aaa\n"
		                ."  1.#2 bbb"));

}
sub test_ko_nested_list {
# простые тесты для списков
# цель - проверить обработку вложенных списков
        my$self=shift;


        $self->assert_equals("<ul><li>aaa\n</li></ul><ul><li>bbb\n</li></ul><ul><li>ccc</li></ul>",
		$self->wiki2Html("      * aaa\n    * bbb\n  * ccc"));

}

sub tear_down {
    # clean up after test
}

1;
