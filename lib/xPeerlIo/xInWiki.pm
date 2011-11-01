#!/usr/bin/perl
package xPeerlIo::xInWiki;

use strict;
use warnings;

use xPeerlIo::xIn;
use xPeerlIo::xOut;

use vars qw(@ISA);
@ISA=qw(xPeerlIo::xIn);

use constant{

};

# класс, разбирающий/фильтрующий wiki-код
# ВОЗМОЖНО содержит определённые привязки к языку
# (например, правила склеивания слов, разделённых переносом).



sub new{
	my($class,$config,$out)=@_;
# на входе - настройки фильтрации, язык и "потребитель" слов
	my$self=$class->SUPER::new($config,$out);
	bless($self,$class);

	$self->{'1px'}		=$config->{'pixelUrl'};
	# Данные хранятся в 3-х стэках; блочные, списковые и строчные команды
	# форматирования. Таблицы - блочные; заголовки, заголовочные ячейки
	# и абзацы (TODO!) - обрабатываются отдельно, с блокировкой строчного
	# вывода фальшивой незакрытой командой.
	# Блочные и списковые команды открываются сразу же, строчные - только
	# при закрытии соотв. тэга.
	# Неожиданно окончившаяся таблица корректно закрывается.
	$self->{'blockStack'}	=[];
			# стэк вложенных блочных тэгов, содержит тройки
			# [команда (текст), атрибуты (полезны для таблиц),
			#  разрешены ли абзацы ($self->{'parEnabled'})]
	
	my$bodyParEnabled=$config->{'bodyParEnabled'};
	$bodyParEnabled=1 if!exists$config->{'bodyParEnabled'};
		# здесь undef трактуется как false
	$self->{'bodyParEnabled'}	=$bodyParEnabled;
			# включены ли абзацы в <body> - если да,
			# то текста без абзацев не будет; если нет, то только
			# если в тексте более одного блока текста,
			# разделённого пустой строкой
	$self->{'parEnabled'}	=$self->{'bodyParEnabled'};
			# разрешены ли абзацы (в <body> - см. выше, 
			# в блоках - только там, где фрагментов текста,
			# разделённых пустой строкой более одного)
			# в некоторых блоках абзацев быть не может вообще
			# (например, в <th>)
	$self->{'parOpened'}	=0;
			# начат ли абзац (ещё нет)
	$self->{'listStack'}	=[];
			# стэк списков, содержит текстовые команды
	$self->{'inLineStack'}	=[];
			# стэк вложенных строчных тэгов, содержит червёрки
			# [тэг(текст), атрибуты(текст), атрибуты(хэш),
			#	что_следом(массив)]
			# атрибуты заданы так, что соответствуют исходному
			# тексту (они потом будут преобразованы в аргументы
			# команд форматирования) пример элемента:
			# ['[[','{ext} /',{&xOU_A_HREF=>'/',
			#		&xOU_A_STYLENAME=>"ext"},[]]],
	# в стеке строчных команд первой может быть команда с тэгом - пустой строкой;
	# цель этого - заблокировать вывод строк до завершения внешнего элемента (например,
	# заголовка), который, неизвестно есть ли вообще (и неизвестно пока не будет закрыт).
	$self->{'inLineStackCache'}={};
			# кэш стэка строчных тэгов; содержит тэг=>место
	$self->{'crValue'}	=$out->specialToText(&xOU_C_CRSRC);
			# невидимый на экране перевод строки - для красоты исходников
	$self->{'brValue'}	=$out->specialToText(&xOU_C_BR);
			# настоящий перевод строки
	$self
}
my%BLOCK_TAGS=(
	'>>'=>xOU_B_QUOTE,	# блочная цитата
	'::'=>xOU_B_SECTION,	# раздел
	'||'=>xOU_T_TABLE,	# таблица
);
my%LIST_TAGS=(
	'*'=>xOU_I_MARKERED,	# маркированный список
	'1'=>xOU_I_NUMBERED,	# нумерованный список
	';'=>xOU_I_GLOSSARY,	# глоссарий (список определений)
	':'=>xOU_I_GLOSSARY	# глоссарий (список определений)
);
my%LIST_ITEM_TAGS=(
	'*'=>xOU_I_ITEM,	# маркированный список
	'1'=>xOU_I_ITEM,	# нумерованный список
	';'=>xOU_I_TITLE,	# заголовок (в глоссарии)
	':'=>xOU_I_DESCRIPTION	# определение (в глоссарии)
);
my%INLINE_TAGS=(
	'[['=>xOU_L_HREF,	# ссылка
#	']]',			# окончание ссылки - здесь не нужно
				# (будет в парных тэгах)

	'<<'=>xOU_L_IMG,	# картинка
#	'((',
#	'))',

	'++'=>xOU_S_INS,	# вставленный текст
	'--'=>xOU_S_DEL,	# удалённый текст
	"''"=>xOU_S_QUOTE,	# процитированный текст
	'##'=>xOU_S_TELETYPE,	# телетайпный текст

	'__'=>xOU_S_UNDERLINE,	# подчёркнутый текст

	'//'=>xOU_S_EM,		# выделенный текст
	'**'=>xOU_S_STRONG,	# усиленный текст
	'^^'=>xOU_S_SUP,	# верхний индекс
	'vv'=>xOU_S_SUB,	# нижний индекс

#	'!!',
	);
my%PAIRED_TAGS=(
# парные тэги, по закрываемому узнаём, что открывали
	'[['=>'0',	# этот парный и НЕ может закрыться сам
	']]'=>'[[',	# но может - так
	'))'=>'((',
	'}}'=>'{{',
	'>>'=>'<<',
);
my@HEADERS=(
	&xOU_B_PAR,	# заголовок 0 - его не бывает, поэтому абзац
	&xOU_B_HDR1,	# заголовок 1
	&xOU_B_HDR2,	# заголовок 2
	&xOU_B_HDR3,	# заголовок 3
	&xOU_B_HDR4,	# заголовок 4
	&xOU_B_HDR5,	# заголовок 5
	&xOU_B_HDR6,	# заголовок 6
	&xOU_B_HDR7,	# заголовок 7
	&xOU_B_HDR8,	# заголовок 8
	&xOU_B_HDR9,	# заголовок 9
	&xOU_B_HDR9	# снова заголовок 9 - ошиблись значит
);
sub _parEnabled{
	# могут ли быть абзацы внутри блока
	# 1 - обязательны (не бывает текста без них)
	# 0 - никогда (только просто текст)
	# undef - если в блоке есть как минимум два фрагмента, разделённых пустой строкой
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$cmdCode=shift;	# код команды
	return undef; 		# пока не ясно, для каких блоков что; TODO - определить
}

sub _openBlockTag{
	# открывает блочный тэг
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$blockCmd=shift;	# команда (в текстовом виде)
	# $_[0]		# ссылка на строку после
	my($attrText,$attrHash)=$self->_readAttrs($blockCmd,$_[0]);
		# атрибуты
	my$cmdCode=$BLOCK_TAGS{$blockCmd};#||&xOU_B_SECTION;
	my$cell=undef;	# атрибут - для таблиц означает что
			# строка не кончилась и это - последняя ячейка
			# xOU_T_HEADER - заголовочная;
			# xOU_T_CELL - строка не кончилась и
			# последняя ячейка - обычная;
			# false - строка кончилась (будет новая или конец таблицы)
	$self->_closeList();
	if(xOU_T_TABLE==$cmdCode){
		$self->{'out'}->open($cmdCode);
		# откроем тэг

		$self->{'out'}->open(xOU_T_SECTION);
		$self->{'out'}->open(xOU_T_ROW);
		if($_[0]=~s/^(\*\*\s+)//s){
				# ячейка заголовка
			$self->{'inLineStack'}=[['',$1,$attrHash,[]]];
			$cell=xOU_T_HEADER;
		}else{
			$cell=xOU_T_CELL;
			$self->{'out'}->open($cell,$attrHash);
		}
	}else{
		$self->{'out'}->open($cmdCode,$attrHash);
		# откроем тэг
	}
	if(@{$self->{'blockStack'}}){
		# если что, абзацы могли уже быть разрешены для этого блока
		# (проверка - если 0 то мы в <body> где __уже__ разрешены)
		$self->{'blockStack'}->[-1+@{$self->{'blockStack'}}]->[2]
			=$self->{'parEnabled'}
			# ...их нужно запомнить
		
	}else{
		# абзацы для <body>
		$self->{'bodyParEnabled'}=$self->{'parEnabled'}
	}
	$self->{'parEnabled'}=$self->_parEnabled($cmdCode);
		# пока абзацы запрещены undef можно переопределить, 0 - нельзя
		# так можно запретить совсем абзацы для некоторых блоков
	
	push@{$self->{'blockStack'}},[$blockCmd,$cell];
		# и запомним что открыли
}
sub _openBlocks{
	my$self=shift;				# Наше Величество ОБЪЕКТ :-)
	# $_[0] теперь строка
	my$blockStack=$self->{'blockStack'};	# стек блочных команд
	my$blockStackLen=0+@{$blockStack};	# его длина

	my$blockLevel=0;	# уровень вложенности
	my$changed=0;
	while($_[0]=~s/^(\:\:|\>\>|\|\|)//s){
		my($blockCmd)=($1);
		my$cmpItem;		# сравниваемый элемент
		if($blockLevel>=$blockStackLen){
			# открываем новую команду
			$self->_openBlockTag($blockCmd,$_[0]);
			$blockStackLen++;
				# стэк команд подрос (но не превзошёл $blockLevel)
			$changed=1
		}elsif((($cmpItem=$blockStack->[$blockLevel])->[0]ne$blockCmd)
			# на этом месте в стеке - другая команда
		){
			$self->_closeBlock($blockLevel);
				# нужно закрыть старую (старые)
			$self->_openBlockTag($blockCmd,$_[0]);
				# открыть новую
			$blockStackLen=$blockLevel+1;
				# стэк сбросился до $blockLevel и подрос
			$changed=1
		}elsif('||'eq$blockCmd){
			# таблица, продолжается
			if(!$cmpItem->[1]){# нет незакрытой ячейки
				$self->{'out'}->open(xOU_T_ROW);
				if($_[0]=~s/^(\*\*\s+)//s){
				# ячейка заголовка
					$self->{'inLineStack'}=[['',$1,{},[]]];
				}else{
					$self->{'out'}->open(
						$cmpItem->[1]=xOU_T_CELL
					);
				}
				$changed=1
			}
			#&&($cmpItem->[2]->{'tBodyStyle'}ne'tBodyStyle')){
			# новая секция (tbody) - TODO
		}# иначе ничего не делать
		$blockLevel++;
	}
	$self->_closeBlock($blockLevel),$changed=1
		if$blockStackLen>$blockLevel;
		# если раньше были блоки, а теперь их не нашлось, закрыть
	$changed
}
sub _openLists{
# открывает очередной элемент списка
	my$self=shift;				# Наше Величество ОБЪЕКТ :-)
	# $_[0] теперь строка
	my$listStack=$self->{'listStack'};	# стек списковых команд
	my$listStackLen=0+@{$listStack};	# его длина

	if($_[0]=~s/^([\000-\040]{2,})(?:\{(\w+)\})?(?:(\;|\*|\:)|(?:(?:\d+|(i|I|a|A))\.(?:\x23(\-?\d+))?))(?:\{(\w+)\})?[\000-\040]+//){
		# если это - список
		my($nSpaces,             $listStyle,  $ulType,          $olType,        $olStart,   $itemStyle)=($1,$2,$3,$4,$5,$6);
		# число пробелов перед   стиль списка атр. кроме нум.    атр. нумер      старт. нум   стиль эл-та
		my$itemText=$ulType||$olType||'1';
			# тип команды (1 - для нумерованых списков)
		my$listCmd=$LIST_TAGS{$itemText};
		$listCmd=xOU_I_NUMBERED if!defined$listCmd;
			# код команды для списка
		my$itemCmd=$LIST_ITEM_TAGS{$itemText};
		$itemCmd=xOU_I_ITEM if!defined$itemCmd;
			# код команды для элемента
		my($listLevel)=(length($nSpaces)>>1)-1;
			# отступ определяет уровень списка
		my$doOpen=0;
		if($listLevel>=$listStackLen){
			# открываем новый список
			$doOpen=1;

		}elsif((($listStack->[$listLevel]||'')ne$itemText)
			# на этом месте уже есть другая команда
			||defined($listStyle)||defined($olStart)
				# или та же, но есть новый стиль списка
				# или новый начальный номер (для нумерованого)
		){	# сначала нужно закрыть
			$self->_closeList($listLevel);
			$doOpen=1;	# а потом - открыть
		}else{	# список тот же, элемент новый
			$self->{'out'}->close($itemCmd);
			$self->{'out'}->open($itemCmd);
		}
		if($doOpen){
			# если нужно открывать
			$listStack->[$listLevel++]=$itemText;
			$listStackLen=$listLevel;
			my$listAttrHash=(
					  defined($listStyle)
					||defined($olStart)
					||defined($olType))
				?{}:undef;
			$listAttrHash->{&xOU_A_STYLENAME}=$listStyle
				if defined($listStyle);
			$listAttrHash->{&xOU_A_LISTSTART}=$olStart
				if defined($olStart);
			$listAttrHash->{&xOU_A_LISTTYPE}=$olType
				if defined($olType);
			# атрибуты или состоят из имени стиля или их нет
			$self->{'out'}->open($listCmd,$listAttrHash);
			my$itemAttrHash=(defined($itemStyle))
				?{}:undef;
			$itemAttrHash->{&xOU_A_STYLENAME}=$itemStyle
				if defined($itemStyle);
			$self->{'out'}->open($itemCmd,$itemAttrHash);
		}
		return 1;	# ДА, список был
	}elsif($_[0]=~s/^([\000-\040]+)//){
		# не список, но в списке продолжает элемент
		# (возможно - с переводом строки)
		my($listLevel)=length($1)>>1;
			# отступ определяет уровень списка
#		if($listLevel>$listStackLen){
		if($listStackLen){
			$self->_closeList($listLevel);
			if($listLevel>$listStackLen){
				$self->{'out'}->writeSpecialText(
					$self->{'brValue'}
				);
			}
			return 1;	# ДА, список был
		}
	}else{
		# иначе нет никакого списка
		$self->_closeList(0),return 1 if$listStackLen;
		# (и можно, например, проверить на заголовки
		# TODO - какое-то оповещение (для абзацев) что он __БЫЛ__
	}
	0	# НЕТ, списка не было
}
sub _openHeader{
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	# $_[0] теперь строка
	if($_[0]=~s/^(=(={1,10})(?:\{(\w+)\})?[\000-\040]+)//){
		# если это - заголовок
		my($asTxt,$hn)=($1,$2);	# текст и уровень
		my$attrHash={};		# хэш атрибутов
		$attrHash->{&xOU_A_STYLENAME}=$3 if defined$3;
			# если есть имя стиля - в атрибуты
		$self->_closeAllInLine();	# закрыть всё строчное
		$self->{'inLineStack'}=[['',$asTxt,$attrHash,[]]];
		return 1	# да, был заголовок
	}
	0			# нет, не заголовок
}
sub _closeHeader{
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	# $_[0] теперь строка
	my$inLineStack=$self->{'inLineStack'};
		# стэк строчных элементов
	my$lastItem=-1+@{$inLineStack};
		# номер последнего строчного элемента
	return if$lastItem<0;
		# если нет последнего, то всё
	my$itemText=$inLineStack->[$lastItem]->[3];
		# завершающие текстовые элементы
	my$lastText=-1+@{$itemText};
		# номер последнего текстового
	# return if$lastText<0; - не бывает, т.к. всегда добавляется текст
	if(
		  ($itemText->[$lastText]=~/[\000-\040]+={2,11}$/)
		&&($inLineStack->[0]->[1]=~/^=(={1,10})/)
		# если оканчивается на === и в стэке есть начало
	){
		my$hn=$1;	# вот это - начиналось
		if($itemText->[$lastText]=~s/[\000-\040]+$hn={0,2}$//s){
			# если закончилось то же (+- одно = для запаса)
			my$cmd=$HEADERS[length$hn];
			$self->{'out'}->open(
				$cmd,
				$inLineStack->[0]->[2]
			);
			$inLineStack->[0]->[1]='';
			return $cmd;
		}
	}
	return 0
}
sub line{
# получает очередную входную строку
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$LN=shift;		# кусок текста

	my$wasCr=($LN=~s/\s*?([\r\n]+)$//s);
		# в конце строки могут быть пробелы - удалить
		# и запомнить
	# сначала - обрабатываются вложенные многострочные
	# разделы, цитаты, ячейки таблицы
	my$cleanLine=1;
	$self->_openBlocks($LN);#?0:1;
	$cleanLine=0		# строка чиста (ни списков, ни заголовков)
		if$self->_openLists($LN)		# списки?
		||$self->_openHeader($LN);	# заголовки
	$LN=~s/^\s+//;
	if(''eq$LN){	# если это пустая строка, то...
		$self->_closeAllInLine()if defined$self->{'parEnabled'};
			# закрыть все тэги
		$self->{'out'}->write($self->{'crValue'})if$wasCr;
		$self->{'wasEmptyLine'}=1;
	}else{
		if($cleanLine&&!$self->{'parOpened'}
					&&!defined($self->{'parEnabled'})){
		# чистая строка, абзац не открыт и не известно - открывать ли
			if(!@{$self->{'inLineStack'}}){
			# текст ещё отсутствует (в том числе фиктивный)
				my($asTxt)=('');	# текст
				my$attrHash={};		# хэш атрибутов
				$self->{'inLineStack'}=[[undef,$asTxt,$attrHash,[]]];
					# фиктивный текст
			}elsif($self->{'wasEmptyLine'}
			# была пустая строка,абзац не открыт
				# &&!defined($self->{'inLineStack'}->[0]->[0])
				# если не ясно про абзац, то эта проверка
				# не нужна
			){
				$self->{'parEnabled'}=1;
				$self->_closeAllInLine();
			}
		}
		if($cleanLine&&!$self->{'parOpened'}&&$self->{'parEnabled'}){
			# если нужно и можно - начать абзац
			$self->{'out'}->open(xOU_B_PAR);
			$self->{'parOpened'}=1
		}

		$self->_inLine($LN);
			# иначе она трактуется как текст
		$self->_addNext($self->{'crValue'})if$wasCr;
			# перевод строки (для красивого форматировани
			# результата)
		$self->{'wasEmptyLine'}=0
			# была НЕ пустая строка
	}
	my$closeHeader=$self->_closeHeader();
		# нужно закрыть этот тэг заголовка
	if($closeHeader){
		# если нужно закрыть заголовок
		$self->_closeAllInLine();
			# то сначала - закрыть все тэги
		$self->{'out'}->close($closeHeader);
			# а потом - его
	}
}
sub _closeBlock{
# закрывает БЛОЧНЫЕ тэги
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$pos=shift||0;	# закрывать этот и следующие
	# сначала нужно закрыть всё строчное и все списки; если есть
	$self->_closeList();	# оно само разберётся ;-)
	my$blockStack=$self->{'blockStack'};	# стек блочных команд
	my$blockStackLen=0+@{$blockStack};	# его длина
	my$out=$self->{'out'};			# получатель команд

	for(my$j=$blockStackLen-1;$j>=$pos;$j--){
		my$cmdText=$blockStack->[$j]->[0];
		my$cmdCode=$BLOCK_TAGS{$cmdText};
		if('||'eq$cmdText){
			# таблица - у неё есть разделы, строки и ячейки
			# может быть их нужно закрыть
			my$attr=$blockStack->[$j]->[1];	# состояние таблицы
			if($attr){
				# незакрытая строка - какова последняя ячейка?
				$out->close($attr);
				$out->close(&xOU_T_ROW);
			}
			$out->close(&xOU_T_SECTION);	# раздел таблицы
		}
		$out->close($cmdCode);
	}
	if($pos){
		# абзацы могли уже быть разрешены для блока, который остался
		# (проверка - если 0 то будеть <body>, см. ниже)
		$self->{'parEnabled'}=$self->{'blockStack'}->[$pos-1]->[2]
			# ...их нужно восстановить
	}else{
		$self->{'parEnabled'}=$self->{'bodyParEnabled'}
		# вернёмся к <body>
	}
	splice@{$blockStack},$pos;
}
sub _closeList{
# закрывает СПИСОЧНЫЕ тэги
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$pos=shift||0;	# закрывать этот и следующие
	# сначала нужно закрыть всё строчное; если есть
	$self->_closeAllInLine();	# оно само разберётся ;-)
	my$listStack=$self->{'listStack'};	# стек блочных команд
	my$listStackLen=0+@{$listStack};	# его длина
	return if!$listStackLen;
	my$out=$self->{'out'};			# получатель команд

	for(my$j=$listStackLen-1;$j>=$pos;$j--){
		my$itemText=$listStack->[$j];
		next if!$itemText;
		my$listCmd=$LIST_TAGS{$itemText};
		$listCmd=xOU_I_NUMBERED if!defined$listCmd;
			# код команды для списка
		my$itemCmd=$LIST_ITEM_TAGS{$itemText};
		$itemCmd=xOU_I_ITEM if!defined$itemCmd;
			# код команды для элемента

		$out->close($itemCmd);
		$out->close($listCmd);
	}
	splice@{$listStack},($pos>$listStackLen?$listStackLen:$pos);
}
sub _out{
# выводит текст или команду
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$val=shift;		# выводимое
	my$out=$self->{'out'};	# получатель результата
#	print STDERR"ref=".ref($val)."\n";
	if('ARRAY'eq ref$val){
		# команда открытия (возможно - с параметрами)
		$out->open(@{$val});
	}elsif(ref$val){
		# ссылка на команду закрытия
		$out->close($$val);
	}else{	# просто текст
		$out->write($val);
	}

}
sub _addNext{
# добавляет текст; всегда - в конец, ЗА последним тэгом
	my$self=shift;	# Наше Величество ОБЪЕКТ :-)
	my$val=shift;
	my$inLineStack=$self->{'inLineStack'};
			# стэк вложенных тэгов
	my$stackLen=0+@{$inLineStack};
		# размер стека
	if($stackLen){
		# если стэк не пуст, то есть предыдущий элемент
		# (последний открытый, но ещё не закрытый)
		my$childs=$inLineStack->[$stackLen-1]->[3];
			# сюда будем складывать
		my$childLen=@{$childs};
		if($childLen && !ref($val) && !ref($childs->[$childLen-1])){
			# предыдущее есть, строку клеим к строке
			$childs->[$childLen-1].=$val;
		}else{
			# не две строки - просто добавим
			push@{$childs},$val;
		}
	}else{
		$self->_out($val);
	}
}
sub _unclosedToText{
# превращает все тэги стека снова в текст
# (кроме вложенные в них и уже корректно закрытых
# применяется для непарных команд, которые ОШИБОЧНО не были открыты
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$pos=shift||0;	# позиция первого закрываемого тэга
	my@OUT;			# сюда запишем результат
	my$inLineStack=$self->{'inLineStack'};
		# стэк вложенных тэгов
	my$stackLen=0+@{$inLineStack};
		# размер стека
	for(my$j=$pos;$j<$stackLen;$j++){
		# все заведомо лишние - непарные тэги, они не закрыты, а внешний - закрывается
		my($txt,$attrText,$attrHash,$childs)=@{$inLineStack->[$j]};
			# команда(текст), атрибуты(текст),
			# атрибуты(хэш) - не потребуется
			# (остальное не потребуется)
		$txt.=$attrText;
		push@OUT,$txt;
		push@OUT,@{$childs};
		undef$txt;
		undef@{$childs};
	}
	\@OUT;
}
sub _closeInLine{
# закрывает строчный тэг;
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$pos=shift||0;	# позиция тэга в inLineStack
	# в корректном случае у нас $pos - верхний элемент
	# иначе - всё, что между $pos и вершиной - просто текст
	# (т.к. всё, что без пары - трактуется как текст)
	my$inLineStack=$self->{'inLineStack'};
		# стэк вложенных тэгов
	my$stackLen=0+@{$inLineStack};
		# размер стека
	return if!$stackLen;
		# ничего нет - до свидания!
	# "мусор" - куски с wiki-разметкой, но с неверным
	# форматированием (незакрытые) - превратим снова в текст
	my$trash=$self->_unclosedToText($pos+1);
		# всё что после текущего, результат - в $trash
	my($myCmd,$myAttrText,$myAttrHash,$myChilds)=@{$inLineStack->[$pos]};
	splice@{$inLineStack},$pos;
		# всё что должно быть ВНУТРИ тэга, теперь точно там - он закрыт
	my$cmdCode=$INLINE_TAGS{$myCmd};		# код ЭТОЙ команды
	# теперь подадим команды - на выход или в родительский тэг
	# (оно само знает)
	$self->_addNext([$cmdCode,$myAttrHash]);	# ЭТА команда
	map{$self->_addNext($_)}@{$myChilds};		# её вложенные
	map{$self->_addNext($_)}@{$trash};		# непарный мусор
	$self->_addNext(\$cmdCode);			# закрыть ЭТУ команду
}
sub _readAttrs{
# читает атрибуты для команды форматирования $cmd;
# подразумевается, что $LN - текст, НЕПОСРЕДСТВЕННО следующий за командой
# (она только что была открыта)
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$cmd=shift;		# команда
	# $_[0] 		- теперь кусок текста
	my$attrHash;		# атрибуты в виде хэша (пока нет)
	my$attrText='';		# атрибуты в виде текста (пока нет)
	if('[['eq$cmd){
		# ссылка; имеет клас и назначение;
		# внутри ссылки - сначала идёт адрес
		if($_[0]=~s/^(\{(?:\^(\w+)[\000-\040]*)?(\w+)?\})//){
			# атрибуты - target и класс
			$attrText=$1;
			$attrHash->{&xOU_A_TARGET}	=$2 if defined$2;
			$attrHash->{&xOU_A_STYLENAME}	=$3 if defined$3;
		}
		if($_[0]=~s/^(\S+)(\s*)(?:([^\]]|\][^\]])|(\]\]))/$4?$1.$2.$4:$3/e){
			# адрес
			$attrText.=$1.$2 if!$4;
				# если адрес - не тот же, что и текст
			$attrHash->{&xOU_A_HREF}	=$1;
		}
	}elsif('<<'eq$cmd){
		# изображение
		return unless $_[0]=~s/^(\{(?:\^(\w+)[\000-\040]*)?(\w+)?\})?(\S*)(?:(\s+)([^\>]+))?(\>\>)/$7/e;
			#              атрибуты  выравнивание и     класс    ссылка  ...    имя      закр.
		# $attrText не понадобится, т.к. проверили, что закроется
		if(defined$1){ 	# есть атрибуты
			$attrText='???';
			$attrHash->{&xOU_A_ALIGN}	=$2 if defined$2;
			$attrHash->{&xOU_A_STYLENAME}	=$3 if defined$3;
		}
		$attrText.=$4.($5||'');
				# если адрес - не тот же, что и текст
		$attrHash->{&xOU_A_ALT}	=defined$6?$6:'';
		$attrHash->{&xOU_A_TITLE}=$6 if defined$6;
		$attrHash->{&xOU_A_SRC}	=(''eq$4)?$self->{'1px'}:$4;
	}elsif('||'eq$cmd){
		# ячейка таблицы;
		if($_[0]=~s/^(\{(?:(\d+)\*(\d+)(?:[\000\040]+(\w+))?|(\w+))\})//){
			$attrText=$1;
			if(defined$2){
				$attrHash={
					&xOU_A_COLSPAN	=>$2,
						# ширина ячейки (в колонках)
					&xOU_A_ROWSPAN	=>$3,
						# высота ячейки (в строках)
				};
				$attrHash->{&xOU_A_STYLENAME}=$4 if defined$4
			}else{
				$attrHash={ &xOU_A_STYLENAME=>$5}
			}
		}
	}elsif($_[0]=~s/^(\{(\w+)?\})//){ # все остальные обычные
		$attrText=$1,$attrHash={&xOU_A_STYLENAME=>$2};
	}
	($attrText,$attrHash);
}
sub _tableInline{
# обрабатывает границу ячеек таблицы внутри строки
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$txt=shift;		# текст до ячейки
	my$lastBlock=shift;	# последний (внутренний) открытый блок
	my$isTableHeader=shift; # признак конца ячейки заголовка
	# $_[0] - терерь строка
	my$closeHeader=0;	# возможно в ячейке - заголовок,
				# его нужно закрыть
	my$openHeader=0;	# ...а этот - в следующей - открыть
	my$inLineStack=$self->{'inLineStack'};
			# стэк вложенных тэгов
	if(!@{$inLineStack}# стэк пуст
		||!defined($inLineStack->[0]->[0])
		||''ne$inLineStack->[0]->[0]){
		# не случай
			$txt.=$isTableHeader	# обратно засунем
				if$isTableHeader;	# обратно засунем

	}elsif($inLineStack->[0]->[1]=~/=(={1,10})/s){
	# в ячейке был заголовок (<h3>, например)
		my$hn=$1;	# вот это - начиналось
		if($isTableHeader){
			$txt.=$isTableHeader;	# обратно засунем
		}elsif($txt=~s/[\000-\040]+$hn={0,2}$//s){
			# если закончилось то же (+- одно = для запаса)
			my$cmd=$HEADERS[length$hn];
			$self->{'out'}->open(
				$cmd,
				$inLineStack->[0]->[2]
			);
			$inLineStack->[0]->[1]='';
			$closeHeader=$cmd;
		}
		# была открыта не ячейка заголовка
	}elsif($isTableHeader){
		$self->{'out'}->open(
			xOU_T_HEADER,
			$inLineStack->[0]->[2]
		);
		$lastBlock->[1]=xOU_T_HEADER;
		$inLineStack->[0]->[1]='';
	}else{
		$self->{'out'}->open(
			xOU_T_CELL,
			$inLineStack->[0]->[2]
		);
		$lastBlock->[1]=xOU_T_CELL;
		$self->{'out'}->write($inLineStack->[0]->[1]);
		$inLineStack->[0]->[1]='';
	}
	$self->_closeAllInLine();
		# всё строчное - закрыть
	$txt=~s/\s+$//s;
	$self->{'out'}->write($txt);
	$self->{'out'}->close($closeHeader);
	# если таблица была в начале входной строки,
	# то строка таблицы точно ещё не кончилась
	# и заведомо есть что закрывать
	$self->_closeList();
		# списки - закрыть
	$self->{'out'}->close($lastBlock->[1]);
	if(''ne$_[0]){
		# ещё не конец строки
		#if($LN=~s/^(\*\*\s+)//s){
		my($attrText,$attrHash)=$self->_readAttrs('||',$_[0]);
		if($_[0]=~s/^(\*\*\s+)//s){
		# ячейка заголовка
			unshift@{$self->{'inLineStack'}},['',$1,$attrHash,[]];
		}else{
			$lastBlock->[1]=xOU_T_CELL; # TODO define
			$self->{'out'}->open(
				$lastBlock->[1],
				$attrHash
			);
			if($_[0]=~s/^(=(={1,10})(?:\{(\w+)\})?[\000-\040]+)//){
				# если это - заголовок
				my$asTxt=$1;
				my$hn=$2;
				my$attrHash={};
				$attrHash->{&xOU_A_STYLENAME}=$3 if defined$3;
				my$cmd=$HEADERS[length$2];
				# длине === соответствует номер заголовка
				$self->{'inLineStack'}=[['',$asTxt,$attrHash,[]]];
			}else{
				$_[0]=~s/^\s+//s;
			}
		}
	}else{
		$lastBlock->[1]=0;
		$self->{'out'}->close(xOU_T_ROW);
	}
}
sub _inLine{
# получает очередной кусочек входной строки
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	my$LN=shift;		# строка текста

	my$blockStack=$self->{'blockStack'};
			# то же для блочных (потребуется для таблиц)
	my$lastBlock=@{$blockStack}?$blockStack->[-1+@{$blockStack}]:0;
			# последний (внутренний) открытый блок
	my$inLineStack=$self->{'inLineStack'};
			# стэк вложенных тэгов
	my$inLineStackCache=$self->{'inLineStackCache'};
			# кэш стэка тэгов; содержит тэг=>место
	my$OUT='';	# выходная строка
	my$finalLine=$self->{'line'};
		# строка
	while($LN=~s/(.*?)((\s+\*\*)?\|\||\[\[|\]\]|\<\<|\>\>|\(\(|\)\)|\+\+|\-\-|\'\'|\#\#|__|\/\/|\*\*|\^\^|vv|\!\!)//s){
		# TODO - escape \\, \|, \" и так далее
		my($txt,$cmd,$isTableHeader)=($1,$3?'||':$2,$3);
		if('||'eq$cmd&&$lastBlock
			&&'||'eq$lastBlock->[0]#($lastBlock->[0]||'')
			# граница ячеек и таблица была;
			&&(!$isTableHeader
				||(0+@{$inLineStack}
					&&''eq($inLineStack->[0]->[0]||'')))
		){
			$self->_tableInline($txt,$lastBlock,$isTableHeader,$LN);
			$inLineStack=$self->{'inLineStack'};
				# стэк вложенных тэгов...
			$inLineStackCache=$self->{'inLineStackCache'};
				# ...и его кэш - были попорчены, возьмём снова
			next
		}elsif($isTableHeader){
		# гипотеза о заголовочной ячейке была ошибкой
			$isTableHeader=~s/\*\*$//;
			$txt.=$isTableHeader;
			$cmd='**';	# т.е. у нас просто **
			my$t='||';	# а || - текст
			$t.=$LN;
			$LN=$t;
			undef$t;
			undef$isTableHeader
		}

		# важно что форматируемый текст не может начинаться с пробела
		# или заканчмваться им,
		# то есть "//aaa bbb//" - корректно, а "// aaa bbb //" - нет.
		my$cmdTxt=$cmd;
			# изначальный вид команды

		my$canClosing=($txt=~/\s$/)?0:1;
			# если перед командой -	пробел, то она НЕ закрывается
		my$canOpening=($LN=~/^(\s|$)/)?0:1;
			# если после команды - пробел (или конец строки),
			# то она НЕ открывается
		my$openingPair=$PAIRED_TAGS{$cmd};
			# есть ли открывающая пара для ЭТОЙ команды
		if($openingPair){		# есть - эта команда - ЗАКРЫВАЮЩАЯ
			$canOpening=0;		# значит - не открывающая
			$cmd=$openingPair;	# ищем где открыли эту
		}elsif(defined$openingPair){	# в списке парных,
			# но сама - открывающая
			$canClosing=0;		# значит - не закрывающая
		}
		my$stackPlace=$inLineStackCache->{$cmd};
			# где команда была открыта
		if($canClosing&&defined$stackPlace){
			# если тэг может закрыться и он был открыт,
			# ... то тэг точно закрывается
			$self->_addNext($txt);
				# добавим текст что был перед закрытием
			delete$inLineStackCache->{$cmd};
			$self->_closeInLine($stackPlace);
		}elsif($canOpening&&!defined$stackPlace){
			# если тэг может открыться и он не был открыт,
			# ... то тэг точно открывается
			$self->_addNext($txt);
				# добавим текст что был перед открытием
			$inLineStackCache->{$cmd}=0+@{$inLineStack};
				# следующая позиция - запомним
			my($attrText,$attrHash)=$self->_readAttrs($cmd,$LN);

			$self->_addNext($txt.$cmdTxt),next
				if!defined$attrText;
			push@{$inLineStack},[$cmd,$attrText,$attrHash,[]];
				# тэг, атрибуты в виде текста и хэша
				# следующие за ним (после его закрытия) команды
		}else{
			# иначе он трактуется как текст
			$self->_addNext($txt.$cmdTxt);
		}
	}
	$self->_addNext($LN);
	undef$LN;
}

sub _closeAllInLine{
# оканчивает очередную __ТЕКСТОВУЮ__ часть строки;
# на то, во что она входит (разделы, цитаты, таблицы) она не влияет
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	$self->{'inLineStackCache'}={};
		# кэш стэка тэгов; содержит тэг=>место; очистим
	# всё что было открыто, но так и не закрыто - в текст
	my$inLineStack=$self->{'inLineStack'};
	if($inLineStack->[0]&&!defined($inLineStack->[0]->[0])){
		#print STDERR"START!";
		if($self->{'parEnabled'}){
			$self->{'out'}->open(xOU_B_PAR);
			$self->{'parOpened'}=1;
		}
		$inLineStack->[0]->[0]='';
	}elsif($inLineStack->[0]&&''eq$inLineStack->[0]->[0]
			&&$inLineStack->[0]->[1]=~/\*\*/s){
		# в стеке - начало таблицы;
		my$blockStack=$self->{'blockStack'};	# стек блочных команд
		$self->{'out'}->open(
			xOU_T_CELL,
			$inLineStack->[0]->[2]
		);
		$blockStack->[-1+@{$blockStack}]->[1]=xOU_T_CELL;
	}
	my$trash=$self->_unclosedToText();
		# всё что было, результат - в $trash
	$self->{'inLineStack'}=[];
		# стэк тэгов; почистим
	map{$self->_out($_)}@{$trash};
	undef@{$trash};
	$self->{'out'}->close(xOU_B_PAR),
	$self->{'parOpened'}=0
		if$self->{'parOpened'}
		# закрыть абзац, если он был
}
sub flush{
# 	заканчивает работу конвертора
	my$self=shift;		# Наше Величество ОБЪЕКТ :-)
	$self->_closeBlock();
	$self->_closeInLine();
}
1;
