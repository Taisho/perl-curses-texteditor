#!/usr/bin/perl -w

#TODO install hooks for window size change
#FIXME When the -y option is set to the texteditor widget, the statusBar (Label) disappears. Fix that

use strict;
use Curses::UI;
use Curses::UI::Common;
use Data::Dumper;
use Switch;

my $gMode = "NULL";

sub applyChanges{
    my $textEditor = shift;

    #DONE split buffer in lines

    my @lines = split "\n", ${$textEditor}->{-text};
    my $flagParse = 0;

    my $dateString = (localtime)[3];
    $dateString .= "." . sprintf "%02d", ((localtime)[4]+1);
    $dateString .= "." . ((localtime)[5] + 1900);

    for my $line (@lines){
	if ($line =~ m/^$dateString$/){
	    $flagParse = 1;
	    next;
	}

	if ($flagParse != 0)
	{
	    $line =~ s/^(?<=\s)CONSIDER\b/____/g;
	}
    }

    my $text = join "\n", @lines;
    ${$textEditor}->{-text} = $text;
}

sub editDummy{
    my $textEditor = shift;

    if ($gMode eq "normal")
    {
	#$textEditor->undo();
    }
}

sub setEditorWidget{
    my $textEditor = shift;
    my $statusBar = shift;
    my $statusEntry = shift;

    sub cusCursorLeft { ${$textEditor}->cursor_left(); }
    sub cusCursorRight { ${$textEditor}->cursor_right(); }
    sub cusCursorUp { ${$textEditor}->cursor_up(); }
    sub cusCursorDown { ${$textEditor}->cursor_down(); }
    sub cusUndo { ${$textEditor}->undo(); }

    sub cusAppend { ${$textEditor}->cursor_right; &setModeInput(); }

    sub cusAppendLine { 
	#DONE go to input mode here
	&setModeInput();

	${$textEditor}->cursor_to_scrlineend();
	${$textEditor}->newline();
    }

    sub cusPrependLine { 
	#DONE go to input mode here
	&setModeInput();

	${$textEditor}->cursor_to_scrlinestart();
	${$textEditor}->newline();
	${$textEditor}->cursor_up();
    }

    sub statusEntryCance{
	${$statusEntry}->{-text} = "";
	${$statusBar}->{-text} = "";
	${$statusBar}->bold(1);

	${$textEditor}->focus();
	$gMode = "normal";
    }

    sub statusEntryExecute{
	#TODO do something with statusEntry's -text
	my $command = ${$statusEntry}->{-text};

	switch ($command)
	{
	    case "q" { exit_dialog() }
	    case "w" { applyChanges($textEditor) }
	}

	${$statusEntry}->{-text} = "";
	${$statusBar}->{-text} = "";
	${$statusBar}->bold(1);

	${$textEditor}->focus();
	$gMode = "normal";
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

my $win1 = $cui->add(
		     'win1', 'Window',
		     -y    => 0,
	     );

my $texteditor = $win1->add("text", "TextEditor",
			-border => 0,
			-bfg  => 'red',
			-undolevels => 4096,
			#-y => 1,
			-onchange => \&editDummy,
			-wrapping => 1,
			-height => $win1->height-1,
			-text => "Here is some text\n"
				. "And some more");

my $statusBar = $win1->add('statusbar', "Label",
			-y => $texteditor->height,
			-width => -1,
			-text => "");
    
my $statusEntry = $win1->add('statusEntry', "TextEntry",
			-y => $texteditor->height,
			-x => 1,
			-width => -1,
			-text => "");

sub setModeInput
{
    $gMode = "input";

    $texteditor->clear_binding("edit-dummy");

    $texteditor->clear_binding("my-cursor-left");
    $texteditor->clear_binding("my-cursor-right");
    $texteditor->clear_binding("my-cursor-up");
    $texteditor->clear_binding("my-cursor-down");
    $texteditor->clear_binding("mode-input");
    $texteditor->clear_binding("my-undo");
    $texteditor->clear_binding("my-append-line");
    $texteditor->clear_binding("my-prepend-line");
    $texteditor->clear_binding("my-append");
    $texteditor->clear_binding("mode-command");
    $texteditor->clear_binding("delete-line");
    $texteditor->clear_binding("delete-character");

    $texteditor->clear_binding("cursor-scrlinestart");
    $texteditor->clear_binding("cursor-scrlineend");

    $texteditor->set_binding("mode-normal", CUI_ESCAPE);

    $statusBar->{-text} = "-- INSERT --";
    $statusBar->draw();
}

#!TASK add keybinding:
    #clear binding in setModeInput()
    #add the key in @normalModeKeys
    #set binding in setModeNormal()

#!--------------------------------------------------------------
#!--------------------------------------------------------------
#DONE make ESC button switches to normal mode
#FIXME the setMode* routines make call on widgets' methods.  Consider make duplicate routines, which will not
#refer widgets.
#!CONSIDER when moving cursor horizontally stop it from going to the next/previous line
#DONE travarse all key codes and assign some dummy function. 
#This is for normal mode.
#FIXED cursor-* movemant functions should be custom!
#DONE bind 'u' for undo
#DONE bind 'o' and 'O'
#DONE bind 'a'
#DONE bind ':'
#DONE bind '^' and '$'
#DONE bind 'x'
#DONE try to add TextEntry on top of the Label, or somehow swap between them
    #the statusLabel is never deleted. When in command mode its width shrinks to 1 character and displays only ":"
    #DONE the statusLabel should go between width 1 and width -1
	#setting width -1 solved the problem. It seems that curses allows for two widgets to occupy the same position
    #DONE ESC key inside statusEntry should bring focus to the TextEditor widget
#DONE install hook for RETURN key in the statusEntry
#NNOTE mode-command may be redudant because the focus is on different widget
#TODO make all widget-referencing functions closures
#DEBUGGED When hitting RETURN inside StatusEntry the focus goes to the TextEditor, but the keys seem to have lost their 
    #event handlers. This is because in command mode the hooks are disabled. Without RETURN hook, the mode is not set
    #properly. 
#DONE when hitting enter inside statusEntry, going back to command mode doesn't work. This is because we don't have a 
    #hook for the enter key. So now the program thinks it is still in command mode, and refuses to change it
#FIXED 'O' doesn't work properly when the cursor is at the first line of the buffer.
#TODO the ESC key seems to wait for another key or something. Make it 'non-greedy' (e.g. not combine with other characters)
#TODO execute commands from statusEntry
#TODO connect to database and begin doing parsing
#DONE undo history is quite short. Increase it.
#!CONSIDER assign multi-key sequences
#!CONSIDER the undo history should work as in vim - a single 'u' stroke should delete everything from the last 'i' edit
#!CONSIDER bind 'v' and 'V'
    #This will require a lot of work	file://ncurses - Highlighting and Selecting text with Python curses - Stack Overflow.html
#!CONSIDER switch to newer version of curses that supports UTF-8 (for example ncursesw)

my @normalModeKeys = qw(h i j k l u o O a : D x ^ $);
@normalModeKeys = sort @normalModeKeys;

sub setModeNormal
{
    if ($gMode eq "normal")
    {
	return;
    }

    $gMode = "normal";

    #Reset @normalModeKeys's internal iterator
    keys @normalModeKeys;

    #Travarse all key codes and assign some dummy function.
    my ($ak, $key);
    ($ak, $key) = each @normalModeKeys;

    #Supress warnings about uninitialized $key value
    no warnings;

    for (my $k=1; $k<=255; $k++)
    {   
	if(ord $key == $k)
	{   
	    ($ak, $key) = each @normalModeKeys;
	    next;
	}

	$texteditor->set_binding("edit-dummy", chr $k);
    }

    $texteditor->set_binding("my-cursor-left", "h");
    $texteditor->set_binding("my-cursor-right", "l");
    $texteditor->set_binding("my-cursor-up", "k");
    $texteditor->set_binding("my-cursor-down", "j");
    $texteditor->set_binding("mode-input", "i");
    $texteditor->set_binding("my-undo", "u");
    $texteditor->set_binding("my-append-line", "o");
    $texteditor->set_binding("my-prepend-line", "O");
    $texteditor->set_binding("my-append", "a");
    $texteditor->set_binding("mode-command", ":");

    $texteditor->set_binding("delete-line", "D");
    $texteditor->set_binding("delete-character", "x");
    $texteditor->set_binding("cursor-scrlinestart", "^");
    $texteditor->set_binding("cursor-scrlineend", "\$");

    $statusBar->{-text} = "";
    $statusBar->intellidraw();
}

sub setModeCommand{
    if ($gMode eq "command")
    {
	return;
    }

    $gMode = "command";


    #TODO rename statusbar to statusLabel
    #$win1->delete("statusbar");
    $statusBar->{-text} = ":";
    $statusBar->{-width} = 1;
    $statusBar->bold(0);


    $statusEntry->focus();
    $statusEntry->intellidraw();

}


setEditorWidget(\$texteditor, \$statusBar, \$statusEntry);

#...register routines
$texteditor->set_routine('my-cursor-left', \&cusCursorLeft);
$texteditor->set_routine('my-cursor-right', \&cusCursorRight);
$texteditor->set_routine('my-cursor-up', \&cusCursorUp);
$texteditor->set_routine('my-cursor-down', \&cusCursorDown);
$texteditor->set_routine('my-undo', \&cusUndo);
$texteditor->set_routine('my-append-line', \&cusAppendLine);
$texteditor->set_routine('my-prepend-line', \&cusPrependLine);
$texteditor->set_routine('my-append', \&cusAppend);

$texteditor->set_routine('mode-input', \&setModeInput);
$texteditor->set_routine('mode-normal', \&setModeNormal);
$texteditor->set_routine('mode-command', \&setModeCommand);
$texteditor->set_routine('edit-dummy', \&editDummy);

$statusEntry->set_routine('my-cancel-command', \&statusEntryCance);
$statusEntry->set_routine('my-execute-command', \&statusEntryExecute);

#obviously this should not be changed
$statusEntry->set_binding("my-cancel-command", CUI_ESCAPE);
$statusEntry->set_binding("my-execute-command", Curses::KEY_ENTER());

setModeNormal();

$cui->set_binding( \&exit_dialog , "\cX");

#$texteditor->focus();
#$texteditor->readonly(1);

$statusBar->bold(1);

$cui->mainloop();

__DATA__

#$statusBar->blink(1);
#$cui->set_binding(sub {$menu->focus()}, "\cX");
$cui->set_binding(sub {$menu->focus(); $win1->refresh($win1)}, CUI_ESCAPE );
$menu->set_binding(sub {$texteditor->focus(); $win1->refresh($win1)}, "i");
$texteditor->set_binding(sub {$texteditor->cursor_left()}, "h");

$cui->set_binding(sub {$menu->focus(); $win1->refresh($win1)}, CUI_ESCAPE );
my $menu = $cui->add(
	'menu','Menubar', 
	-menu => \@menu,
	-fg  => "blue",
);
