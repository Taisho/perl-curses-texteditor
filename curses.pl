#!/usr/bin/perl -w

use strict;
use Curses::UI;
use Curses::UI::Common;
use Data::Dumper;

my $cui = new Curses::UI( -color_support => 1 );
my $dump;

my @menu = (
  { -label => 'File', 
    -submenu => [
   { -label => 'Exit      ^Q', -value => \&exit_dialog  }
		]
   },
);

sub exit_dialog()
{
    my $return = $cui->dialog(
	    -message   => "Do you really want to quit?",
	    -title     => "Are you sure???", 
	    -buttons   => ['yes', 'no'],

    );

    if ($return)
    {
	open(my $fh, ">log");
	print $fh $dump;
	close($fh);
	exit(0);
    }
}

my $menu = $cui->add(
	'menu','Menubar', 
	-menu => \@menu,
	-fg  => "blue",
);

my $win1 = $cui->add(
		     'win1', 'Window',
		     -border => 1,
		     -y    => 1,
		     -bfg  => 'red',
	     );

my $texteditor = $win1->add("text", "TextEditor",
			 -text => "Here is some text\n"
				. "And some more");

#$cui->set_binding(sub {$menu->focus()}, "\cX");
$cui->set_binding(sub {$menu->focus() }, CUI_ESCAPE );
$menu->set_binding(sub {$texteditor->focus(); }, "i");

## PATTERN binding key to another character
$texteditor->set_binding(sub {$texteditor->add_string("i")}, "p");
$dump = Dumper($texteditor);

$cui->set_binding( \&exit_dialog , "\cX");

#$texteditor->focus();
$cui->mainloop();

