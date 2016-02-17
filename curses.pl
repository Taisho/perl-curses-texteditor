#!/usr/bin/perl -w

#TODO install hooks for window size change
#FIXME When the -y option is set to the texteditor widget, the statusBar (Label) disappears. Fix that

use strict;
use Curses::UI;
use Curses::UI::Common;
use Data::Dumper;

my $gMode = "normal";

sub editCallback{
    my $textEditor = shift;

    if ($gMode eq "normal")
    {
	$textEditor->undo();
    }
}

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
		     -y    => 1,
	     );

my $texteditor = $win1->add("text", "TextEditor",
			-border => 0,
			-bfg  => 'red',
			#-y => 1,
			-onchange => \&editCallback,
			-wrapping => 1,
			-height => $win1->height-3,
			-text => "Here is some text\n"
				. "And some more");

my $statusBar = $win1->add('statusbar', "Label",
			-y => $texteditor->height,
			-width => -1,
			-text => " Here is status bar");

$texteditor->set_binding("cursor-left", "h");
$texteditor->set_binding("cursor-right", "l");
$texteditor->set_binding("cursor-up", "k");
$texteditor->set_binding("cursor-down", "j");

sub setModeInput
{
    if ($gMode eq "normal")
    {
	$gMode = "input";
	#$texteditor->set_binding(undef, "h");
	$texteditor->clear_binding("cursor-left");
	$texteditor->clear_binding("cursor-right");
	$texteditor->clear_binding("cursor-up");
	$texteditor->clear_binding("cursor-down");

	$texteditor->clear_binding("mode-input");
    }
}

$texteditor->set_routine('mode-input', \&setModeInput);

$texteditor->set_binding('mode-input', "i");

$cui->set_binding(sub {$menu->focus(); $win1->refresh($win1)}, CUI_ESCAPE );

#$dump = Dumper($texteditor);

$cui->set_binding( \&exit_dialog , "\cX");

#$texteditor->focus();
#$texteditor->readonly(1);

$cui->mainloop();

__DATA__

#$statusBar->blink(1);
#$cui->set_binding(sub {$menu->focus()}, "\cX");
$cui->set_binding(sub {$menu->focus(); $win1->refresh($win1)}, CUI_ESCAPE );
$menu->set_binding(sub {$texteditor->focus(); $win1->refresh($win1)}, "i");
$texteditor->set_binding(sub {$texteditor->cursor_left()}, "h");
