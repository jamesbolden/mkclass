#!/usr/bin/perl
use warnings;
use strict;
use File::Slurp;

$standard_indent = "    ";
$super_class_string = " ";
@pri_ms = [];
@pro_ms = [];
@getters = [];
@setters = [];
@accessors = [];
%adv_info = ();

my $class_name = "*";
my $namespace = "*";
my $loc_inc_path = ".";
my $proj_path = ".";
my $src_path = ".";
my $hdr_ext = ".hh";
my $src_ext = ".cc";
my @supers = [];
my @include = [];
my @local_include = [];
my @priv_mems = [];
my @prot_mems = [];

my $spec = read_file($ARGV[0]);
my $len = length($spec);
my $progress = 1;

sub parse_list($l) {
    return split(/,/, $l ~= s/\s+//g);
}

sub nl_nonempty($f, @arr) {
    if (length @arr > 0) { print {$f} "\n"; }
}

sub handle_mems(@mems) {
    my @hm = [];

    foreach (@mems) {
        my @m = split(/:/, $_);

        if (length @m > 1) {
            @m[2] = split(/|/, @m[2]);
        }

        push(@hm, @m);
    }

    return @hm;
}

sub add_sigs(@arr, $k) {
    foreach (@arr) {
        my $t_s = "const ".@_[1];

        if ($k eq "|gs") {
            if (substr @_[1], -1 eq "*") {
                $t_s = $t_s." const";
            }
            else if (substr_[1], -1 ne "&") {
                $t_s = $t_s."&";
            }
        }

        switch ($k) {
            "|gs"   { my $sig = $t_s." ".@_[0]."() const"; $adv_info{@_[0].$k} = $sig; }
            "|ss"   { my $sig = "void ".@_[0]."(".$t_s.")"; $adv_info{@_[0].$k} = $sig; }
            "|as"   { my $sig = $t_s."& ".@_[0]."()"; $adv_info{@_[0].$k} = $sig; }
            else    { die "\nmkclass: Invalid member accessor type!\n"; }
        }
    }
}

sub handle_mem_access {
    foreach (@pro_ms) {
        if (length @_ > 2) {
            my @m = $_;
            foreach (@_[2]) {
                switch (uc($_)) {
                    "GET" { push @getters, @m[0, 1]; }
                    "SET" { push @setters, @m[0, 1]; }
                    "ACC" { push @accessors, @m[0, 1]; }
                    else  { die "\nmkclass: Invalid member accessor type!\n"; }
                }
            }
        }
    }

    foreach (@pri_ms) {
        if (length @_ > 2) {
            my @m = $_;
            foreach (@_[2]) {
                switch (uc($_)) {
                    "GET" { push @getters, @m[0, 1]; }
                    "SET" { push @setters, @m[0, 1]; }
                    "ACC" { push @accessors, @m[0, 1]; }
                    else  { die "\nmkclass: Invalid member accessor type!\n"; }
                }
            }
        }
    }
    
    add_sigs(@getters, "|gs");
    add_sigs(@setters, "|ss");
    # add_sigs(@accessors, "|as");
}

sub print_hdr_mems($hf, $ind, $a, @mems) {
    print {$hf} $ind.$a.":\n";

    foreach(@mems) {getters

sub print_hdr_gsas($hf, $ind) {
    foreach (@getters) {
        print {$hf} $ind.$standard_indent.$adv_info{@_[0]."|gs"}.";\n";
    }

    nl_nonempty($hf, @getters);

    foreach (@setters) {
        print {$hf} $ind.$standard_indent."void ".@_[0]."(".@_[1].");\n";
    }

    nl_nonempty($hf, @setters);

    #foreach (@accessors) {
    #    print {$hf} $ind.$standard_indent.$adv_info{@_[0]."|as"}.";\n";
    #}
    #nl_nonempty($hf, @accessors);
}

sub print_hdr_contents($hf, $indent) {
    print {$hf} $indent."class ".$class_name.$super_class_string."{\n";
    print {$hf} $indent."public:\n";
    print {$hf} $indent.$standard_indent.$class_name."();\n";
    print {$hf} $indent.$standard_indent."~"$class_name."();\n\n";

    print_hdr_gsas($hf, $indent);
    
    print_hdr_mems($hf, $indent, "protected", $pro_ms);
    print {$hf} "\n";    
    print_hdr_mems($hf, $indent, "private", $pri_ms);
}

sub print_src_gsas($sf, $ind) {
    foreach (@getters) {
        my $sig = $adv_info{@_[0]."|gs"};
        $sig =~ s/(.*)(@_[0])(.*)/$1$class_name::$2$3/;

        print {$sf} $ind.$sig." { return ".@_[0]."_; }\n"
    }

    foreach (@setters) {
        print {$sf} $ind."void ".$class_name."::"."set_".@_[0]."(".@_[1]." x) { ".@_[0]."_ = x; }\n"
    }

    # TODO: needs fixin'
    #foreach (@accessors) {
    #    my $sig = $adv_info{@_[0]."|as"};
    #    $sig =~ s/(.*)(@_[0])(.*)/$1$class_name$2$3/;
    #
    #    print {$sf} $ind.$sig." { return ".@_[0]."_; }\n"
    #}
}

sub print_src_contents($sf, $ind) {
    print {$sf} $ind.$class_name."::".$class_name."() { }\n\n";
    print {$sf} $ind."~".$class_name."::".$class_name."() { }\n\n";
    
    print_src_gsas($sf, $ind);
}

while (1) {
    my @assign = ($spec =~ /(\w+):(.*);/);
    my $adv = index($spec, ';');

    if ($adv = -1) {
        last;
    }

    my $var = uc(@assign[0]);
    my $val = @assign[1];

    switch ($var) {
        case "NAME"                 { $class_name = $val; }
        case "NAMESPACE"            { $namespace = $val; }
        case "PROJECT_PATH"         { $proj_path = $val; }
        case "SOURCE_PATH"          { $src_path = $val; }
        case "LOCAL_INCLUDE_PATH"   { $loc_inc_path = $val; }
        case "HEADER_EXT"           { $hdr_ext = $val; }
        case "SOURCE_EXT"           { $src_ext = $val; }
        case "INCLUDE"              { @includes = split /,/, parse_list($val); }
        case "INCLUDE_LOCAL"        { @local_includes = split /,/, parse_list($val); }
        case "SUPERCLASSES"         { @supers = parse_list($val); }
        case "PRIVATE_MEMBERS"      { @priv_mems = split /,/, parse_list($val); }
        case "PROTECTED_MEMBERS"    { @prot_mems = split /,/, parse_list($val); }
    }

    $spec = substr($spec, $adv + 1);
    $progress = $progress + $adv;
    
    if ($progress >= $len) {
        last;
    }
}

if ($class_name = "*") {
    die "\nmkclass: Invalid specification!\n";
}

if (length @supers > 0) {
    $super_class_string = " : ";
    foreach (@supers) {
        if ($index = 0) {
            $super_class_string = $super_class_string."public ".$_;
        }
        else {
            $super_class_string = $super_class_string." , public".$_;
        }
    }
    $super_class_string = $super_class_string." ";
}

@pri_ms = handle_mems(priv_mems);
@pro_ms = handle_mems(prot_mems);

my $hdr_path = $loc_inc_path."/".$class_name.$hdr_ext;
my $src_file_path = $src_path."/".$class_name.$src_ext;

open my $hdr_file, '>', $hdr_path;
open my $src_file, '>', $src_file_path;

my $hdr_def = ($hdr_path =~ /.*include\/(.*)/);
$hdr_def = uc($hdr_def =~ s/\./_/g =~ s/\//_/g);

print {$hdr_file} "#ifndef ".$hdr_def."\n";
print {$hdr_file} "#define ".$hdr_def."\n"
print {$hdr_file} "\n";

if ($namespace ne "*") {
    print {$hdr_file} "namespace ".$namespace." {\n";
    print_hdr_contents($hdr_file, $standard_indent);
    print {$hdr_file} "}\n"
}
else {
    print_hdr_contents($hdr_file, "");
}

print {$hdr_file} "\n";
print {$hdr_file} "#endif //".$hdr_def."\n";

print {$src_file} "#include \"".$loc_inc_path."/".$class_name.$hdr_ext."\n\n";

if ($namespace ne "*") {
    print {$src_file} "namespace ".$namespace." {\n";
    print_src_contents($src_file, $standard_indent);
    print {$src_file} "}\n";
}
else {
    print_src_contents($src_file, "");
}

close $hdr_file;
close $src_file;