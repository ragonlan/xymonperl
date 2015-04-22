# xymonperl
Perl Module to program Xymon extensions easily.<br />

Basic use:
#!/usr/bin/perl
```
use Xymon;
use Xymon::Graph;
```
# Loading environment variables from xymon config.
```
my %config = &loadenv();
```
# Test
```
my $xymon = new Xymon ($TESTNAME);
$xymon->green;
$xymon->say("HELLO WORLD");
$xymon->print("ALL IS DONE.");
$xymon->say("OK.");
$xymon->red();
$xymon->send;
```
# Graph
```
my $object = new Xymon::Graph($TESTNAME);
$object->insert("ds0" , '4');
$object->insert("ds1" , '12');
$object->send;
```
