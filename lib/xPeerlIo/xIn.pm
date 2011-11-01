#!/usr/bin/perl
package xPeerlIo::xIn;

use strict;
use warnings;

sub new{
	my($object,$config,$out)=@_;
# на входе - настройки фильтрации, язык и "потребитель" результата
	my$self={
		'config'=>$config,
		'out'=>$out,
			# получатель результата;
			# чаще всего другой конвертор
	};
	bless($self);
}
sub write{
	my$self=shift;
	my$IN=shift;
	while($IN=~s/^(.*?\r?\n)//){
		$self->line($1);
	}
	$self->line($IN)if''ne$IN;
}
sub flush{
# по-умолчанию ничего не делает
}
1;