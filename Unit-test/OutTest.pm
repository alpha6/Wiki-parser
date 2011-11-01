#!/usr/bin/perl
package OutTest;

use lib qw(../lib);
use strict;
use warnings;

use base qw(Test::Unit::TestCase);

use xPeerlIo::xOut;


sub new {
    my $self = shift()->SUPER::new(@_);
    # your state for fixture here
    return $self;
}


sub getHtmlOut{
	my$self=shift;
        my$baseConfig=$self->{'baseConfig'};
        my$OUT='';
	my$out=xPeerlIo::xOut->new($baseConfig,sub{$OUT.=$_[0]});
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
sub test_ok {
# простые тесты для форматирования
# цель - проверить поддержку __ВСЕХ__ команд
        my$self=shift;

        my($out,$OUT)=$self->getHtmlOut();
        $self->assert_equals($out->specialToText(&xOU_C_CRSRC),"\n");# невидимый перевод строки - для красоты

	$out->open(&xOU_B_HDR1);
	$out->open('unknoooown');
	$out->open(&xOU_B_HDR2,undef);
	$out->write('<A>');
	$out->open(&xOU_B_HDR2,'');
	$out->write("\n");
	$out->write($out->specialToText(&xOU_C_CRSRC));
	$out->open(&xOU_B_HDR2,{'unknown'=>123});
	$out->open(&xOU_B_HDR2,{&xOU_A_TITLE=>'A'});
	$out->write('"&"B');
	$out->writeSpecialText('><');
	$out->close(&xOU_B_HDR2);
	$out->close('unknoooown');
	$self->assert_equals("<A>\n\n\"&\"B><",$$OUT);
}

sub tear_down {
    # clean up after test
}

1;
