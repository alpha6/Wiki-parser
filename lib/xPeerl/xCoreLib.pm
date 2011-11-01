#!/usr/bin/perl
package xPeerl::xCoreLib;

use strict;
use warnings;

our@EXPORT=qw(
	&xDoUrlEscape &xUrlEscape
	&xDoUrlUnEscape &xUrlUnEscape
	&xDoHtmlEscape &xHtmlEscape
	&xDoHtmlAttrEscape &xHtmlAttrEscape
	&xDoHtmlUnEscape &xHtmlUnEscape
	&xDoEscape &xEscape

	&xResolvePath
);

our@EXPORT_OK=@EXPORT;
sub import{goto &Exporter::import}

# набор костылей

sub xDoUrlEscape{
	# обрабатывает аргумент, URL-кодируя
	eval'$_[0]=~s/([^A-Z^a-z^0-9^_^-^.^ ])/"%".uс(sprintf"%02x",ord($1))/eg;$_[0]=~s/ /+/g;1;';
		# в eval - чтобы не хранить (потенциальные) мегабайты в $'
}
sub xUrlEscape{
	# URL-кодирует; оставляет аргумент неизменным
	my$v=$_[0];
	&xDoUrlEscape($v);
	$v
}
sub xDoUrlUnEscape{
	# обрабатывает аргумент, раскрывая URL-кодирование
	eval'$_[0]=~s/\\+/ /g;$_[0]=~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;1;';
		# в eval - чтобы не хранить (потенциальные) мегабайты в $'
}
sub xUrlUnEscape{
	# раскрывает URL-кодирование; оставляет аргумент неизменным
	my$v=$_[0];
	&xDoUrlUnEscape($v);
	$v
}

sub xDoHtmlEscape{
	# обрабатывает аргумент, заменяя символы на html-entities
	$_[0]=~s/\&/\&amp;/g;$_[0]=~s/\"/\&quot;/g;$_[0]=~s/>/\&gt;/g;$_[0]=~s/</\&lt;/g;
}
sub xHtmlEscape{
	# подставляет html-entities; оставляет аргумент неизменным
	my$v=$_[0];
	&xDoHtmlEscape($v);
	$v
}
sub xDoHtmlAttrEscape{
	# обрабатывает аргумент, заменяя символы на html-entities, в том числе переводы строк
	$_[0]=~s/\&/\&amp;/g;$_[0]=~s/\"/\&quot;/g;$_[0]=~s/>/\&gt;/g;$_[0]=~s/</\&lt;/g;
	$_[0]=~s/\000/\&\#0;/g;
	$_[0]=~s/\011/\&\#9;/g;
	$_[0]=~s/\012/\&\#10;/g;
	$_[0]=~s/\015/\&\#13;/g;
}
sub xHtmlAttrEscape{
	# подставляет html-entities, в том числе переводы строк; оставляет аргумент неизменным
	my$v=$_[0];
	&xDoHtmlAttrEscape($v);
	$v
}
sub xDoHtmlUnEscape{
	# обрабатывает аргумент, раскрывая html-entities (не все)
	$_[0]=~s/\&quot;/\"/ig;$_[0]=~s/\&#34;/\"/ig;
	$_[0]=~s/\&gt;/>/ig;$_[0]=~s/\&#62;/>/ig;
	$_[0]=~s/\&lt;/</ig;$_[0]=~s/\&#60;/</ig;
	$_[0]=~s/\&amp;/\&/ig;$_[0]=~s/\&#38;/\&/ig;
}
sub xHtmlUnEscape{
	# раскрывает html-entities (не все); оставляет аргумент неизменным
	my$v=$_[0];
	&xDoHtmlUnEscape($v);
	$v
}

sub xDoEscape{
	# обрабатывает аргумент, скрывая ' " \ \r \n и нулевой байт за слэшем
	$_[0]=~s/\\/\\\\/g;
	$_[0]=~s/\"/\\\"/g;
	$_[0]=~s/\'/\\\'/g;
	$_[0]=~s/\r/\\r/g;
	$_[0]=~s/\n/\\n/g;
	$_[0]=~s/\000/\\000/g;
}
sub xEscape{
	# скрывает ' " \ \r \n и нулевой байт за слэшем, не изменяет аргумент
	my$v=$_[0];
	&xDoEscape($v);
	$v
}

sub xResolvePath{
	# сокращает .. и . в пути
	my$path=shift;		# путь
	my$root=shift;		# корень - используется только для пути,
				# начинающегося не с /
#	print STDERR"$path -> ";
	$path=$root.'/'.$path if defined($root)&&$path!~m%^/%;
	$path=~s%//+%/%g;		# // -> /
	$path=~s%(/\.)+(/|$)%/%g;	# /./ -> /	;	/.[конец] -> /
	# TODO - FIX BUG IN peerl.pl: s%/\.(/|$)%/%g; -> s%(/\.)+(/|$)%/%g;
	while($path=~s%/([^/^.][^/]*|\.([^/^.][^/]*|\.[^/]+))/\.\.(/|$)%/%g){
		# удаляются .. - пока можно
	}
	return if$path=~m%/\.\.(/|$)%;	# не все .. убраны - ничего не вернули
#	print STDERR" $path\n";
	$path
}
1;
