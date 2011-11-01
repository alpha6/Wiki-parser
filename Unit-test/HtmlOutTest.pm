#!/usr/bin/perl
package HtmlOutTest;

use lib qw(../lib);
use strict;
use warnings;

use base qw(Test::Unit::TestCase);

use xPeerlIo::xOut;
use xPeerlIo::xOutXhtml;


sub new {
    my $self = shift()->SUPER::new(@_);
    # your state for fixture here
    return $self;
}


sub getHtmlOut{
	my$self=shift;
        my$baseConfig=$self->{'baseConfig'};
        my$OUT='';
	my$out=xPeerlIo::xOutXhtml->new($baseConfig,sub{$OUT.=$_[0]});
        return($out,\$OUT);
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
sub test_ok_open {
# простые тесты для форматирования
# цель - проверить поддержку __ВСЕХ__ команд
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	map{$out->open($_)}(
		&xOU_B_HDR1,&xOU_B_HDR2,&xOU_B_HDR3,
		&xOU_B_HDR4,&xOU_B_HDR5,&xOU_B_HDR6,
		&xOU_B_HDR7,&xOU_B_HDR8,&xOU_B_HDR9);
	$self->assert_equals("<h1><h2><h3><h4><h5><h6><h6><p><p>",$$OUT);
	$$OUT='-';
	map{$out->open($_)}(
		&xOU_B_PAR,&xOU_B_SECTION,
		&xOU_B_QUOTE,&xOU_B_PREFORMAT);
	$self->assert_equals("-<p><div><blockquote><pre>",$$OUT);

	# ссылки
	($out,$OUT)=$self->getHtmlOut();
	map{$out->open($_)}(
		&xOU_L_ANCHOR,&xOU_L_HREF);
	$self->assert_equals("<a><a>",$$OUT);
	map{$out->open($_)}(
		&xOU_T_TABLE,&xOU_T_CAPTION,&xOU_T_SECTION,
		&xOU_T_ROW,&xOU_T_HEADER,&xOU_T_CELL);
	$self->assert_equals("<a><a><table><caption><tbody><tr><th><td>",$$OUT);
	$$OUT='';
	# списки
	map{$out->open($_)}(
		&xOU_I_NUMBERED,&xOU_I_MARKERED,&xOU_I_GLOSSARY,
		&xOU_I_ITEM,&xOU_I_TITLE,&xOU_I_DESCRIPTION);
	$self->assert_equals("<ol><ul><dl><li><dt><dd>",$$OUT);
	# в строке
	$$OUT='-';
	map{$out->open($_)}(
		&xOU_S_INS,&xOU_S_DEL,&xOU_S_QUOTE,&xOU_S_TELETYPE,
		&xOU_S_UNDERLINE,&xOU_S_EM,&xOU_S_STRONG,&xOU_S_SUP,&xOU_S_SUB);
	$self->assert_equals("-<ins><del><cite><tt><u><em><strong><sup><sub>",$$OUT);
}
sub test_ko_open_unknown {
# простые тесты для форматирования
# цель - проверить обработку неизвестных команд
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	map{$out->open($_)}(
		&xOU_B_HDR1,'unknown shit',&xOU_B_HDR2);
	$self->assert_equals("<h1><h2>",$$OUT);
}
sub test_ok_close {
# простые тесты для форматирования
# цель - проверить поддержку команды закрытия
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	map{$out->close($_)}(
		&xOU_B_HDR1,&xOU_B_HDR2,&xOU_B_HDR3,
		&xOU_B_HDR4,&xOU_B_HDR5,&xOU_B_HDR6,
		&xOU_B_HDR7,&xOU_B_HDR8,&xOU_B_HDR9);
	$self->assert_equals("</h1></h2></h3></h4></h5></h6></h6></p></p>",$$OUT);
}
sub test_ko_close_unknown {
# простые тесты для форматирования
# цель - проверить обработку неизвестных команд
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	map{$out->close($_)}(
		&xOU_B_HDR1,'unknown shit',&xOU_B_HDR2);
	$self->assert_equals("</h1></h2>",$$OUT);
}
sub test_ok_print {
# простые тесты для форматирования
# цель - проверить поддержку вывода текста
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
        $self->assert_equals("\n",$out->specialToText(&xOU_C_CRSRC));# невидимый перевод строки - для красоты
        $self->assert_equals('<br/>',$out->specialToText(&xOU_C_BR));# ...и обычный

	map{$out->write($_)}('A',$out->specialToText(&xOU_C_CRSRC),'B');
	$self->assert_equals("A\nB",$$OUT);
}
sub test_ok_print_escape {
# простые тесты для форматирования
# цель - проверить поддержку команды закрытия
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	map{$out->write($_)}('A"','<h1>','&2"B');
	$out->writeSpecialText('><');

	$self->assert_equals("A&quot;&lt;h1&gt;&amp;2&quot;B><",$$OUT);
}
sub test_ok_attrs_all {
# простые тесты для форматирования
# цель - проверить поддержку атрибутов
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	$out->open(&xOU_B_HDR1,{
			&xOU_A_ID	=>'id0',		# id элемента
			&xOU_A_NAME	=>'name0',	# имя
			&xOU_A_STYLENAME=>'class0',	# имя стиля (класс)
			&xOU_A_TITLE	=>'title0',	# заголовок (всплывающая подсказка)
		});
	$self->assert_equals("<h1 id=\"id0\" name=\"name0\""
		." class=\"class0\" title=\"title0\">",$$OUT);
	$$OUT="";
	map{$out->open(@{$_})}(
		[&xOU_L_HREF,{
			&xOU_A_HREF	=>'2href',	# адрес ссылки
			&xOU_A_TARGET	=>'2target',	# назначение ссылки
		}],
		[&xOU_T_CELL,{
			&xOU_A_COLSPAN	=>'col3span',	# ширина ячейки (в колонках)
			&xOU_A_ROWSPAN	=>'row3span',	# высота ячейки (в строках)
		}]);
	$self->assert_equals("<a href=\"2href\" target=\"2target\">"
		."<td colspan=\"col3span\" rowspan=\"row3span\">",$$OUT);
	$$OUT="";
	$out->open(&xOU_I_NUMBERED,{
			&xOU_A_LISTTYPE	=>'LISTtype',	# тип нумерованного списка
			&xOU_A_LISTSTART=>'LISTstart',	# начальное значение списка
		});
	$self->assert_equals("<ol type=\"LISTtype\" start=\"LISTstart\">",$$OUT);
}

sub test_ok_attrs_escape {
# простые тесты для форматирования
# цель - проверить поддержку закрытия атрибутов
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	$out->open(&xOU_B_HDR1,{
			&xOU_A_STYLENAME=>'"&',	# имя стиля (класс)
			&xOU_A_TITLE	=>"<h\n1>",	# заголовок (всплывающая подсказка)
		});
	$self->assert_equals("<h1 class=\"&quot;&amp;\" title=\"&lt;h&#10;1&gt;\">",$$OUT);
}
sub test_ko_attrs_unknown {
# простые тесты для форматирования
# цель - проверить поддержку неизвестных атрибутов
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	$out->open(&xOU_B_HDR1,{
			&xOU_A_STYLENAME=>'1',	# имя стиля (класс)
			&xOU_A_ID=>undef,	#
			-999999		=>'13',	# неведома зверюшка
			&xOU_A_TITLE	=>'2',	# заголовок (всплывающая подсказка)
		});
	$self->assert_equals("<h1 id=\"id\" class=\"1\" title=\"2\">",$$OUT);
}
sub test_ko_attrs_not_hash {
# простые тесты для форматирования
# цель - проверить поддержку хреновых атрибутов
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
	$out->open(&xOU_B_HDR1,'A');
	$out->open(&xOU_B_HDR2,undef);
	$self->assert_equals("<h1><h2>",$$OUT);
}

sub tear_down {
    # clean up after test
}

1;
