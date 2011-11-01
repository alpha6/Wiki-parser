#!/usr/bin/perl
package xPeerlIo::xOut;

use strict;
use warnings;

# класс, создающий код по результату входного фильтра xIn****
# класс абстрактный и немощный, состоит главным образом из комментариев

# константы
use constant{
	# абзацы и им подобные блочные штуки
	xOU_B_HDR1	=> 1,	# заголовок 1
	xOU_B_HDR2	=> 2,	# заголовок 2
	xOU_B_HDR3	=> 3,	# заголовок 3
	xOU_B_HDR4	=> 4,	# заголовок 4
	xOU_B_HDR5	=> 5,	# заголовок 5
	xOU_B_HDR6	=> 6,	# заголовок 6
	xOU_B_HDR7	=> 7,	# заголовок 7
	xOU_B_HDR8	=> 8,	# заголовок 8
	xOU_B_HDR9	=> 9,	# заголовок 9
	xOU_B_PAR	=>10,	# абзац
	xOU_B_QUOTE	=>11,	# блочная цитата
	xOU_B_PREFORMAT	=>12,	# преформатированный текст
	xOU_B_SECTION	=>13,	# раздел

	# ссылки
	xOU_L_ANCHOR	=>30,	# якорь
	xOU_L_HREF	=>31,	# ссылка

	xOU_L_IMG	=>35,	# картинка

	# таблицы
	xOU_T_TABLE	=>71,	# таблица
	xOU_T_CAPTION	=>72,	# заголовок таблицы
	xOU_T_SECTION	=>73,	# раздел таблицы
	xOU_T_ROW	=>74,	# строка таблицы
	xOU_T_HEADER	=>75,	# ячейка заголовка таблицы
	xOU_T_CELL	=>76,	# ячейка таблицы

	# списки
	xOU_I_NUMBERED	=>101,	# нумерованный список
	xOU_I_MARKERED	=>102,	# маркированны список
	xOU_I_GLOSSARY	=>103,	# глоссарий (список определений)
	xOU_I_ITEM	=>104,	# элемент списка (кроме глоссария)
	xOU_I_TITLE	=>105,	# заголовок (в глоссарии)
	xOU_I_DESCRIPTION =>106,	# определение (в глоссарии)

	# в строке
	xOU_S_INS	=>121,	# вставленный текст
	xOU_S_DEL	=>122,	# удалённый текст
	xOU_S_QUOTE	=>123,	# процитированный текст
	xOU_S_TELETYPE	=>124,	# телетайпный текст

	xOU_S_UNDERLINE	=>140,	# подчёркнутый текст

	xOU_S_EM	=>160,	# выделенный текст
	xOU_S_STRONG	=>161,	# усиленный текст
	xOU_S_SUP	=>162,	# верхний индекс
	xOU_S_SUB	=>163,	# нижний индекс

	xOU_C_CR	=>1024,	# перевод строки
	xOU_C_CRSRC	=>undef,# невидимый перевод строки - для красоты исходников

	# атрибуты
	xOU_A_ID	=>1,	# id элемента
	xOU_A_NAME	=>2,	# имя
	xOU_A_STYLENAME	=>3,	# имя стиля (класс)
	xOU_A_TITLE	=>4,	# заголовок (всплывающая подсказка)

	xOU_A_HREF	=>10,	# адрес ссылки
	xOU_A_TARGET	=>11,	# назначение ссылки

	xOU_A_SRC	=>15,	# адрес изображения
	xOU_A_ALT	=>17,	# альтернативный текст
	xOU_A_ALIGN	=>18,	# выравнивание картинки

	xOU_A_COLSPAN	=>20,	# ширина ячейки (в колонках)
	xOU_A_ROWSPAN	=>21,	# высота ячейки (в строках)

	xOU_A_LISTTYPE	=>30,	# тип нумерованного списка
	xOU_A_LISTSTART	=>31,	# начальное значение списка

	xOU_C_CRSRC	=>0x0a,	# невидимый перевод строки - для красоты
				# в HTML - как есть
	xOU_C_BR	=>0x0d,	# перевод строки
};
our@EXPORT=qw(
	xOU_B_HDR1	xOU_B_HDR2	xOU_B_HDR3	xOU_B_HDR4	xOU_B_HDR5
	xOU_B_HDR6	xOU_B_HDR7	xOU_B_HDR8	xOU_B_HDR9
	xOU_B_PAR 	xOU_B_QUOTE	xOU_B_PREFORMAT	xOU_B_SECTION

	xOU_L_ANCHOR	xOU_L_HREF	xOU_L_IMG

	xOU_T_TABLE	xOU_T_CAPTION	xOU_T_SECTION
	xOU_T_ROW	xOU_T_HEADER	xOU_T_CELL

	xOU_I_NUMBERED	xOU_I_MARKERED	xOU_I_GLOSSARY
	xOU_I_ITEM	xOU_I_TITLE	xOU_I_DESCRIPTION

	xOU_S_INS	xOU_S_DEL	xOU_S_QUOTE	xOU_S_TELETYPE
	xOU_S_UNDERLINE

	xOU_S_EM	xOU_S_STRONG	xOU_S_SUP	xOU_S_SUB

	xOU_A_ID	xOU_A_NAME	xOU_A_STYLENAME	xOU_A_TITLE

	xOU_A_HREF	xOU_A_TARGET	xOU_A_SRC	xOU_A_ALT
	xOU_A_ALIGN

	xOU_A_COLSPAN	xOU_A_ROWSPAN

	xOU_A_LISTTYPE	xOU_A_LISTSTART

	xOU_C_CRSRC xOU_C_BR
);
our@EXPORT_OK=@EXPORT;
sub import{goto &Exporter::import}

sub new{
	my($object,$config,$out)=@_;
# на входе - настройки фильтрации, язык и "потребитель" результата
	my$self={
		'config'=>$config,
		'out'=>$out,
			# потребитель результата;
			# функция, получающая один аргумент - кусочек результата
	};
	bless($self);
}
sub open{
# открывает тэг	- по-умолчанию ничего не делает
}
sub close{
# закрывает тэг	- по-умолчанию ничего не делает
}
sub write{
# получает очередную входную строку для выхода
# и сразу выводит её; обычно переопределяется для экранирования
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$LN=shift;		# кусок текста
	$self->{'out'}->($LN);
}
sub writeSpecialText{
# получает очередную входную строку для выхода
# и сразу выводит её; обычно не требует переопределения - не экранирует
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$LN=shift;		# кусок текста
	$self->{'out'}->($LN);
}
sub specialToText{
# превращает код специального символа (константу) в текст
# примеры: неразрывный пробел, перевод строки, влияющий только на исходники (как в html),
# знаки копирайта и торговой марки, длинное тире и т.д.
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$code=shift;		# кусок текста
	chr($code);
		# "отмазка" - пока считаем, что код символа совпадает со значением константы
}
1;
