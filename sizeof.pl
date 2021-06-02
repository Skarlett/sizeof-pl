#!/usr/bin/env perl
######################
## Script is used to find the file/dir size
## or evaluate size conversions
#######
use strict;
use warnings;
use 5.30.0;
use File::Find;
use POSIX;

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

my $PRINT_FP = 0;
my $USAGE = "sizeof [file/dir/number] [opts]\nA script to evaluate file sizes, and conversion.\nexample: perl sizeof.pl /mnt/media -p --regex .txt\n\nOPTS:\n\t--help -h\n\t--regex -r [pattern]\n\t--path -p\n\t--symbol -s (b/mb/kb/gb/tb/pb)";
my @SIZES = (
    "B",
    "KB",
    "MB",
    "GB",
    "TB",
    "PB",
);
my $FLOATING_PNT = qr/[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)/;
my $SIZE_INPUT= qr/b|kb|mb|gb|tb|tb|pb/;
sub sym_to_pow {
    my $i = 0;
    if ($_[0]) {
        for(@SIZES) {
            if ($_ eq uc $_[0]) {
                last;
            }
            $i += 1;
        }

        return $i;
    }
    return 0;
}
sub bytes_to_hsize {
    my ($nbytes, $pow) = @_;
    my $h_size_trimmed;
    my $p;

    if ($pow == -1) {
        $p = floor(log($nbytes)/log(1024));
    } else {
        $p = $pow
    }

    my $h_size = $nbytes/1024**$p;
    if ($p eq 0) {
        # Bytes should not have a decimal place
        $h_size_trimmed = floor($h_size);
    }
    else {
        my $h_size_float_i = floor(abs(log($h_size)/log(10)));
        $h_size_trimmed = sprintf("%.${h_size_float_i}f", $h_size); 
    }
    print "$h_size_trimmed $SIZES[$p]\n";
}

sub hsize_to_bytes {
    my ($hsize, $pow) = @_;
    return $hsize*(1024**$pow)
}

sub size_of_fp {
  my ($dir, $re) = @_;
  my $total = 0;
  
  find(sub {
        if (-f and /$re/) {
            my $fsize = (stat _)[7];
            if ($PRINT_FP) {
                print "$File::Find::name\t\t${fsize}\n";
            }
            $total += $fsize;
        }
    }, $dir);
    return $total;
}

sub main {
  my $re = qr/(.*)/;
  my $first_arg = ".";
  my $help_flag = 0;

  # d for default
  my $symbol = 'd';

  GetOptions(
    'regex|r=s' => \$re,
    'symbol|s=s' => \$symbol,
    'path|p' => \$PRINT_FP,
    'help|h' => \$help_flag
  );
  

  if ($help_flag) {
    print "$USAGE\n";
    exit(0);
  }

  if (@ARGV) { 
    $first_arg=$ARGV[0];
  }

  # User specified human size
  if ($symbol ne 'd') {
    $symbol = sym_to_pow($symbol)
  }
  else {
    $symbol = -1;
  }
  
  if ( -e $first_arg) {
    bytes_to_hsize(size_of_fp($first_arg, $re), $symbol);
  } 

  elsif ($first_arg =~ /^$FLOATING_PNT(||$SIZE_INPUT)$/) {
      #bytes_to_hsize($first_arg, $symbol);
      #$first_arg =~ s/[0-9]+//;
      my $num = $first_arg;
      $num =~ s/$SIZE_INPUT//;
      $first_arg =~ s/${FLOATING_PNT}//;
      
      print "input sym: $first_arg\n";
      $first_arg = sym_to_pow($first_arg); # change symbol
      
      print("input: $num\npow: $first_arg\n");

      my $nbytes = hsize_to_bytes($num, $first_arg);
      print "output pow: $symbol\n";
      
      bytes_to_hsize($nbytes, $symbol);
  }

  else {
      print "first argument must be a file/dir or a number\n";
      exit(1);
  }
}

main();
