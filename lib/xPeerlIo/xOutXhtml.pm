#!/usr/bin/perl
package xPeerlIo::xOutXhtml;

use strict;
use warnings;

use xPeerlIo::xOut;
use xPeerl::xCoreLib;

use vars qw(@ISA);
@ISA=qw(xPeerlIo::xOut);

my%TAGS=(
	&xOU_B_HDR1	=> 'h1',	# заголовок 1
	&xOU_B_HDR2	=> 'h2',	# заголовок 2
	&xOU_B_HDR3	=> 'h3',	# заголовок 3
	&xOU_B_HDR4	=> 'h4',	# заголовок 4
	&xOU_B_HDR5	=> 'h5',	# заголовок 5
	&xOU_B_HDR6	=> 'h6',	# заголовок 6
	&xOU_B_HDR7	=> 'h6',	# заголовок 7 - не бывает в HTML!
	&xOU_B_HDR8	=> 'p',		# заголовок 8 - не бывает в HTML!
	&xOU_B_HDR9	=> 'p',		# заголовок 9 - не бывает в HTML!
	&xOU_B_PAR	=> 'p',		# абзац
	&xOU_B_SECTION	=> 'div',	# раздел
	&xOU_B_QUOTE	=>'blockquote',	# блочная цитата
	&xOU_B_PREFORMAT=>'pre',	# преформатированный текст

	# ссылки
	&xOU_L_ANCHOR	=> 'a',		# якорь
	&xOU_L_HREF	=> 'a',		# ссылка
	&xOU_L_IMG	=> 'img',	# картинка


	# таблицы
	&xOU_T_TABLE	=>'table',	# таблица
	&xOU_T_CAPTION	=>'caption',	# заголовок таблицы
	&xOU_T_SECTION	=>'tbody',	# раздел таблицы
	&xOU_T_ROW	=>'tr',		# строка таблицы
	&xOU_T_HEADER	=>'th',		# ячейка таблицы
	&xOU_T_CELL	=>'td',		# ячейка таблицы

	# списки
	&xOU_I_NUMBERED	=>'ol',		# нумерованый
	&xOU_I_MARKERED	=>'ul',	# маркированы
	&xOU_I_GLOSSARY	=>'dl',	# глоссарий (список определений)
	&xOU_I_ITEM	=>'li',	# элемент списка (кроме глоссария)
	&xOU_I_TITLE	=>'dt',	# заголовок (в глоссарии)
	&xOU_I_DESCRIPTION =>'dd',	# определение (в глоссарии)

	# в строке
	&xOU_S_INS	=>'ins',	# вставленный текст
	&xOU_S_DEL	=>'del',	# удалённый текст
	&xOU_S_QUOTE	=>'cite',	# процитированный текст
	&xOU_S_TELETYPE	=>'tt',		# телетайпный текст

	&xOU_S_UNDERLINE=>'u',		# подчёркнутый текст

	&xOU_S_EM	=>'em',		# выделенный текст
	&xOU_S_STRONG	=>'strong',	# усиленный текст
	&xOU_S_SUP	=>'sup',	# верхний индекс
	&xOU_S_SUB	=>'sub',	# нижний индекс

);
my%ATTRS=(
	&xOU_A_ID	=>'id',		# id элемента
	&xOU_A_NAME	=>'name',	# имя
	&xOU_A_STYLENAME=>'class',	# имя стиля (класс)
	&xOU_A_TITLE	=>'title',	# заголовок (всплывающая подсказка)

	&xOU_A_HREF	=>'href',	# адрес ссылки
	&xOU_A_TARGET	=>'target',	# назначение ссылки
	&xOU_A_SRC	=>'src',	# адрес картинки
	&xOU_A_ALT	=>'alt',	# альтернативный текст
	&xOU_A_ALIGN	=>'align',	# выравнивание

	&xOU_A_COLSPAN	=>'colspan',	# ширина ячейки (в колонках)
	&xOU_A_ROWSPAN	=>'rowspan',	# высота ячейки (в строках)

	&xOU_A_LISTTYPE	=>'type',	# тип нумерованного списка
	&xOU_A_LISTSTART=>'start',	# начальное значение списка
);
my%CHARS=(
	&xOU_C_BR	=>'<br/>',	# id элемента
);
my%LONELY=(
	&xOU_L_IMG	=>1
);
sub new{
	my($class,$config,$out)=@_;
# на входе - настройки фильтрации, язык и "потребитель" результата
	my$self=$class->SUPER::new($config,$out);
	bless($self,$class);
}
sub open{
# открывает тэг
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$tag=shift;		# тэг (код, не значение)
	my$attrHash=shift;	# атрибуты (хэш)
	my$lonely=$LONELY{$tag}?'/':'';
				# непарный тэг - сразу же закрывается
	$tag=$TAGS{$tag};
	return if!$tag;
		# возьмём строку-значение тэга; нет - возврат
	my$attrText='';		# атрибуты (текст)
	if('HASH'eq ref$attrHash){
		foreach(sort keys%{$attrHash}){
			my$var=$ATTRS{$_};
				# имя атрибута
			next if!$var;
			my$val=$attrHash->{$_};
				# значение;
			$val=$var if!defined$val;
				# для ключей без значения; например
				# <input disabled="disabled".../>
			&xDoHtmlAttrEscape($val);
			$attrText.=" $var=\"";
			$attrText.=$val;
			$attrText.="\"";
		}
	}
	$self->{'out'}->("<$tag$attrText$lonely>");

}
sub write{
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$val=shift;		# выводимое значение
	&xDoHtmlEscape($val);
	$self->{'out'}->($val);
}
sub close{
# закрывает тэг
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$tag=shift;		# тэг (код, не значение)
	return if$LONELY{$tag};	# непарный тэг - не нужно закрывать
	$tag=$TAGS{$tag};
	return if!$tag;
		# возьмём строку-значение тэга; нет - возврат
	$self->{'out'}->("</$tag>");

}
sub specialToText{
# превращает код специального символа (константу) в текст
# примеры: неразрывный пробел, перевод строки, влияющий только на исходники (как в html),
# знаки копирайта и торговой марки, длинное тире и т.д.
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$code=shift;		# кусок текста
	$CHARS{$code}||$self->SUPER::specialToText($code);
		# "отмазка" - пока считаем, что код символа совпадает со значением константы

}

1;
