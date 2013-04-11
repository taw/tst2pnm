#!/usr/bin/perl -w

# Converts RPGToolkit's TST format to PNM

use integer;

$/=undef;

for my $fn(@ARGV) {
    my $outfn = $fn;
    $outfn =~ s/\.tst$/\.pnm/i;

    if(-e $outfn) {
        warn "$outfn already exists, skipping $fn";
        next;
    }

    print STDERR "Processing $fn\n";
    open IN, $fn;
    $_ = <IN>;
    close IN;
    my $sz = length $_;

    my $PICS_PER_LINE = 12;

    my ($magic, $cnt, $unk) = unpack "SSS", substr($_, 0, 6);
    if($magic != 20) {
        warn "Invalid magic $magic in file $fn";
        next;
    }
    if(($cnt*3*32*32+6) != $sz) {
        warn("Invalid size $sz, expected ".($cnt*3*32*32+6)) ;
        next;
    }

    for $i(0..($cnt-1)) {
        # Pics are inverted normally
        my $pic = substr $_, 6+(3*32*32)*$i, (3*32*32);
        my $pic2= "";
        for my $y(0..31) {
            for my $x(0..31) {
                $pic2 .= substr $pic, 3*(32*$x+$y), 3;
            }
        }
        push @pics, $pic2;
#        push @pics, $pic;
    }

    my $out = "";

    # Don't black-fill if there's less than 2 line of pics
    $PICS_PER_LINE = @pics if @pics < $PICS_PER_LINE;

    while(@pics) {
        while(@pics < $PICS_PER_LINE) {
            push @pics, ("\x00" x (3*32*32));
        }
        @pN = splice @pics, 0, $PICS_PER_LINE;
        # Each line
        for my $y(0..31) {
            # From all pics
                for my $p(@pN) {
                my $pline = substr $p, $y*3*32, 3*32;
                $out .= $pline;
            }
        }
    }
    open OUT, ">", $outfn;

    # TODO: Format them as N pics per line
    print OUT "P6\n";
    printf OUT "%d %d\n", (32*$PICS_PER_LINE), 32*(($cnt+$PICS_PER_LINE-1) / $PICS_PER_LINE);
    print OUT "255\n";
    print OUT $out;
    
    close OUT;
}
