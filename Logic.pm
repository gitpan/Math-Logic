package Math::Logic ;    # Documented at the __END__.

# $Id: Logic.pm,v 1.1 2000/02/19 20:03:37 root Exp root $


require 5.004 ;

use strict ;
use integer ; # Forces us to quote all hash keys.

use Carp ;

use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS ) ;
$VERSION     = '1.00' ;

use Exporter() ;

@ISA         = qw( Exporter ) ;

@EXPORT_OK   = qw( TRUE FALSE UNDEF STR_TRUE STR_FALSE STR_UNDEF ) ;
%EXPORT_TAGS = ( 
    ALL => [ @EXPORT_OK ],
    NUM => [ qw( TRUE FALSE UNDEF ) ],
    STR => [ qw( STR_TRUE STR_FALSE STR_UNDEF ) ],
    ) ;


### Public class constants

use constant TRUE          =>  1 ;
use constant FALSE         =>  0 ;
use constant UNDEF         => -1 ;

use constant STR_TRUE      => 'TRUE' ;
use constant STR_FALSE     => 'FALSE' ;
use constant STR_UNDEF     => 'UNDEF' ;


### Private class constants

use constant DEF_VALUE     => FALSE() ;
use constant DEF_DEGREE    => 3 ;
use constant MIN_DEGREE    => 2 ;
use constant DEF_PROPAGATE => FALSE() ;

use constant KEY_VALUE     => '-value' ;
use constant KEY_DEGREE    => '-degree' ;
use constant KEY_PROPAGATE => '-propagate' ;

use constant PROPAGATE     => KEY_PROPAGATE() ;


### Private data and methods 
#
#   _croak          class   object
#   _set                    object
#   _get                    object
#   _cmp                    object

{
    my %_valid_object_key = (
        KEY_VALUE()     => undef,
        KEY_DEGREE()    => undef,
        KEY_PROPAGATE() => undef,
        ) ;


    sub _croak { # Class and object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        my $error = (caller(1))[3] ;
        croak $error . "() " . shift() . "\n" ;
    }

    sub _set { # Object method
        # Caller is responsible for ensuring the assigned value is valid
        my $self  = shift ;
        my $class = ref( $self ) || $self ;
        my $field = shift ;

        eval {
            croak "is an object method" unless ref $self ;
            croak "invalid field $field" 
            unless exists $_valid_object_key{$field} ;
        } ;
        $class->_croak( $@ ) if $@ ;

        $self->{$field} = shift ;
    }

    sub _get { # Object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;
        my $field = shift ;

        eval {
            croak "is an object method" unless ref $self ;
            croak "invalid field $field" 
            unless exists $_valid_object_key{$field} ;
        } ;
        $class->_croak( $@ ) if $@ ;

        $self->{$field} ;
    }

    sub _cmp { # Object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;
        my $comp  = shift ;

        eval {
            croak "is an object method"                unless ref $self ;
            $comp = $self->new( KEY_VALUE() => $comp ) unless ref $comp ;
            croak "$self and $comp are incompatible" 
            unless $self->compatible( $comp ) ;    
        } ;
        $class->_croak( $@ ) if $@ ;

        $self->value <=> $comp->value ; 
    }
 
}


### Public methods

sub new_from_string { # Class and object method
    my $self   = shift ;
    my $class  = ref( $self ) || $self ;
    my $string = shift ;

    my @arg = $string =~ /\(?\s*([^,\s\%]+)\%?,\s*([^,\s]+)(?:,\s*([^,\s]+))?\)?/o ;

    if( defined $arg[1] ) {
        if( $arg[1] =~ /^[23]$/o ) {    # 2 or 3 value logic
            $arg[0] = TRUE() if defined $arg[0] and $arg[0] =~ /^-?[tT]/o ;
        }
        else {                          # Multi-value logic
            $arg[0] = $arg[1] if defined $arg[0] and $arg[0] =~ /^-?[tT]/o ;
            $arg[0] = FALSE() if defined $arg[0] and $arg[0] =~ /^-?[fF]/o ;
        }
    }
    $arg[2] = $arg[2] =~ /^-?[tTpP1]/o ? TRUE() : FALSE() if defined $arg[2] ; 

    # Ignores settings of calling object if called as an object method.
    $class->new( 
        KEY_VALUE()     => $arg[0] || DEF_VALUE(),
        KEY_DEGREE()    => $arg[1] || DEF_DEGREE(),
        KEY_PROPAGATE() => $arg[2] || DEF_PROPAGATE(),
        ) ;
}


sub new { # Class and object method
    my $self   = shift ;
    my $class  = ref( $self ) || $self ;
    my $object = ref $self ? $self : undef ;
    my %arg    = @_ ;

    # Set defaults plus parameters
    $self = {
            KEY_VALUE()     => DEF_VALUE(),
            KEY_DEGREE()    => DEF_DEGREE(),
            KEY_PROPAGATE() => DEF_PROPAGATE(),
            %arg
        } ;

    # If called as an object method use the calling object's settings unless a
    # parameter has overridden
    if( defined $object ) {
        $self->{KEY_VALUE()}     = $object->value     
        unless exists $arg{KEY_VALUE()} ; 
        $self->{KEY_DEGREE()}    = $object->degree    
        unless exists $arg{KEY_DEGREE()} ; 
        $self->{KEY_PROPAGATE()} = $object->propagate 
        unless exists $arg{KEY_PROPAGATE()} ; 
    }
    
    # Ensure the settings are valid
    $self->{KEY_PROPAGATE()} = $self->{KEY_PROPAGATE()} ? TRUE() : FALSE() ;

    $self->{KEY_DEGREE()}    = DEF_DEGREE() 
    unless $self->{KEY_DEGREE()} =~ /^\d+$/o ;
    $self->{KEY_DEGREE()}    = DEF_DEGREE() 
    if $self->{KEY_DEGREE()} < MIN_DEGREE() ; 

    $self->{KEY_VALUE()} = DEF_VALUE() if $self->{KEY_VALUE()} !~ /^(?:\d+|-1)$/o ;

    if( $self->{KEY_DEGREE()} == 2 ) {      # 2-value logic
        $self->{KEY_VALUE()} = ( $self->{KEY_VALUE()} and 
                                 $self->{KEY_VALUE()} != UNDEF() ) ? 
                                    TRUE() : FALSE() ;
        delete $self->{KEY_PROPAGATE()} ; # Don't store what we don't use
    }
    elsif( $self->{KEY_DEGREE()} == 3 ) {   # 3-value logic
        if( $self->{KEY_VALUE()} != UNDEF() ) {
            $self->{KEY_VALUE()} = $self->{KEY_VALUE()} ? TRUE() : FALSE() ;
        }
    }
    else {                                  # Multi-value logic
        $self->{KEY_VALUE()} = FALSE() if $self->{KEY_VALUE()} == UNDEF() ;
        $self->{KEY_VALUE()} = $self->{KEY_DEGREE()} 
        if $self->{KEY_VALUE()} > $self->{KEY_DEGREE()} ;
        delete $self->{KEY_PROPAGATE()} ; # Don't store what we don't use
    }

    bless $self, $class ;
}


use overload
        '""'       => \&as_string,
        '0+'       => \&value,
        'bool'     => \&value,
        '<=>'      => \&_cmp,
        '&'        => \&and,
        '|'        => \&or,
        '^'        => \&xor,
        '!'        => \&not,
        # Avoid surprises
        '='        => sub { croak "=() unsupported" },
        '+'        => sub { croak "+() unsupported" },
        '-'        => sub { croak "-() unsupported" },
        '*'        => sub { croak "*() unsupported" },
        '/'        => sub { croak "/() unsupported" },
        '%'        => sub { croak "%() unsupported" },
        'x'        => sub { croak "x() unsupported" },
        '**'       => sub { croak "**() unsupported" },
        '<<'       => sub { croak "<<() unsupported" },
        '>>'       => sub { croak ">>() unsupported" },
        '+='       => sub { croak "+=() unsupported" },
        '-='       => sub { croak "-=() unsupported" },
        '*='       => sub { croak "*=() unsupported" },
        '/='       => sub { croak "/=() unsupported" },
        '%='       => sub { croak "%=() unsupported" },
        'x='       => sub { croak "x=() unsupported" },
        '++'       => sub { croak "++() unsupported" },
        '--'       => sub { croak "--() unsupported" },
        'lt'       => sub { croak "lt() unsupported" },
        'le'       => sub { croak "le() unsupported" },
        'gt'       => sub { croak "gt() unsupported" },
        'ge'       => sub { croak "ge() unsupported" },
        'eq'       => sub { croak "eq() unsupported" },
        'ne'       => sub { croak "ne() unsupported" },
        '**='      => sub { croak "**=() unsupported" },
        '<<='      => sub { croak "<<=() unsupported" },
        '>>='      => sub { croak ">>=() unsupported" },
        'cmp'      => sub { croak "cmp() unsupported" },
        'neg'      => sub { croak "neg() unsupported" },
        'nomethod' => sub { croak @_ . "() unsupported" },
        ;


sub value { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $value = shift ;

    $class->_croak( "is an object method" ) unless ref $self ;

    if( defined $value ) {
        my $result ;

        if( $self->degree == 2 ) {      # 2-value logic
            $result = ( $value and $value != UNDEF() ) ? TRUE() : FALSE() ;
        }
        elsif( $self->degree == 3 ) {   # 3-value logic
            $result = $value ? TRUE() : FALSE() ;
            $result = UNDEF() if $value eq UNDEF() ;
        }
        else {                          # Multi-value logic
            $result = $value ;
            $result = FALSE() if $value eq UNDEF() or $value !~ /^\d+$/o ;
            $result = $self->degree if $result > $self->degree ;
        }

        $self->_set( KEY_VALUE() => $result ) ;
    }
    
    $self->_get( KEY_VALUE() ) ;
}


sub degree { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;

    eval {
        croak "is an object method" unless ref $self ;
        croak "cannot be changed"   if @_ ;
    } ;
    $class->_croak( $@ ) if $@ ;
    
    $self->_get( KEY_DEGREE() ) ;
}


sub propagate { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;

    eval {
        croak "is an object method" unless ref $self ;
        croak "cannot be changed"   if @_ ;
    } ;
    $class->_croak( $@ ) if $@ ;
    
    $self->degree == 3 ? $self->_get( KEY_PROPAGATE() ) : FALSE() ;
}


sub compatible { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $comp  = shift ;

    eval {
        croak "is an object method" unless ref $self ;
        croak "can only be applied to $class objects not $comp"
        if ( not ref $comp ) or 
           ( not $comp->can( 'degree' ) ) or 
           ( not $comp->can( 'propagate' ) ) ;
    } ;
    $class->_croak( $@ ) if $@ ;
    
    $self->degree    == $comp->degree and
    $self->propagate == $comp->propagate ; 
}


sub as_string { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $full  = shift || 0 ;
    $full     = 0 unless $full eq '1' or $full eq '-full' ;

    $class->_croak( "is an object method" ) unless ref $self ;

    my $result = '' ;

    if( $self->degree == 2 ) {      # 2-value logic
        $result = $self->value ? STR_TRUE() : STR_FALSE() ;
    }
    elsif( $self->degree == 3 ) {   # 3-value logic
        $result = $self->value ? STR_TRUE() : STR_FALSE() ;
        $result = STR_UNDEF() if $self->value == UNDEF() ;
    }
    else {                          # Multi-value logic
        if( $self->value == FALSE() ) {
            $result = STR_FALSE() ;
        }
        elsif( $self->value == $self->degree ) {
            $result = STR_TRUE() ;
        }
        else {
            $result = $self->value ;
            $result .= '%' if $self->degree == 100 and $full ;
        }
    }

    # e.g. $logic->as_string( -full ) ;
    $result = "($result," . $self->degree . 
                ( $self->propagate ? "," . PROPAGATE() : '' ) . ")" if $full ; 

    $result ;
}


sub and { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $comp  = shift ;

    eval {
        croak "is an object method"                unless ref $self ;
        $comp = $self->new( KEY_VALUE() => $comp ) unless ref $comp ;
        croak "$self and $comp are incompatible" 
        unless $self->compatible( $comp ) ;    
    } ;
    $class->_croak( $@ ) if $@ ;

    my $value ;
    my $result = $self->new ;

    if( $self->degree == 2 ) {      # 2-value logic
        $value = ( $self->value and $comp->value ) ? TRUE() : FALSE() ;
    }
    elsif( $self->degree == 3 ) {   # 3-value logic
        if( $self->propagate ) {
            if( $self->value == UNDEF() or $comp->value == UNDEF() ) {
                # At least one is undefined which propagates.
                $value = UNDEF() ;
            }
            elsif( $self->value == TRUE() and $comp->value == TRUE() ) {
                # They're both defined and true.
                $value = TRUE() ;
            }
            else {
                # They're both defined and at least one is false.
                $value = FALSE() ;
            }
        }
        else {
            if( $self->value == TRUE() and $comp->value == TRUE() ) {
                # Both are defined and true.
                $value = TRUE() ;
            }
            elsif( $self->value == FALSE() or $comp->value == FALSE() ) {
                # At least one is defined and false.
                $value = FALSE() ;
            }
            else {
                # Either both are undefined or only one is defined and true.
                $value = UNDEF() ;
            }
        }
    }
    else {                          # Multi-value logic
        # and is the lowest value
        $value = $self->value < $comp->value ? $self->value : $comp->value ;
    }

    $result->value( $value ) ;

    $result ;
}


sub or { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $comp  = shift ;

    eval {
        croak "is an object method"                unless ref $self ;
        $comp = $self->new( KEY_VALUE() => $comp ) unless ref $comp ;
        croak "$self and $comp are incompatible" 
        unless $self->compatible( $comp ) ;    
    } ;
    $class->_croak( $@ ) if $@ ;
    
    my $value ;
    my $result = $self->new ;

    if( $self->degree == 2 ) {      # 2-value logic
        $value = ( $self->value or $comp->value ) ? TRUE() : FALSE() ;
    }
    elsif( $self->degree == 3 ) {   # 3-value logic
        if( $self->propagate ) {
            if( $self->value == UNDEF() or $comp->value == UNDEF() ) {
                # At least one is undefined which propagates.
                $value = UNDEF() ;
            }
            elsif( $self->value == TRUE() or $comp->value == TRUE() ) {
                # They're both defined and at least one is true.
                $value = TRUE() ;
            }
            else {
                # They're both defined and both are false.
                $value = FALSE() ;
            }
        }
        else {
            if( $self->value == TRUE() or $comp->value == TRUE() ) {
                # At least one is defined and true.
                $value = TRUE() ;
            }
            elsif( $self->value == FALSE() and $comp->value == FALSE() ) {
                # They're both defined and false.
                $value = FALSE() ;
            }
            else {
                # Either both are undefined or one is defined and false.
                $value = UNDEF() ;
            }
        }
    }
    else {                          # Multi-value logic
        # or is the greatest value
        $value = $self->value > $comp->value ? $self->value : $comp->value ;
    }

    $result->value( $value ) ;

    $result ;
}


sub xor { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $comp  = shift ;

    eval {
        croak "is an object method"                unless ref $self ;
        $comp = $self->new( KEY_VALUE() => $comp ) unless ref $comp ;
        croak "$self and $comp are incompatible" 
        unless $self->compatible( $comp ) ;    
    } ;
    $class->_croak( $@ ) if $@ ;
    
    my $value ;
    my $result = $self->new ;

    if( $self->degree == 2 ) {      # 2-value logic
        $value = ( $self->value xor $comp->value ) ? TRUE() : FALSE() ;
    }
    elsif( $self->degree == 3 ) {   # 3-value logic
        # Same truth table whether propagating or not.
        if( $self->value == UNDEF() or $comp->value == UNDEF() ) {
            # At least one is undefined which propagates.
            $value = UNDEF() ;
        }
        elsif( $self->value == $comp->value ) {
            # Both are defined and they're both the same.
            $value = FALSE() ;
        }
        else {
            # Both are defined and they're different.
            $value = TRUE() ;
        }
    }
    else {                          # Multi-value logic
        # or is the greatest value
        $value = $self->value > $comp->value ? $self->value : $comp->value ;
        # but xor is false if the two values are the same
        $value = FALSE() if $self->value == $comp->value ;
    }

    $result->value( $value ) ;

    $result ;
}


sub not { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;

    $class->_croak( "is an object method" ) unless ref $self ;
    
    my $value ;
    my $result = $self->new ;

    if( $self->degree == 2 ) {      # 2-value logic
        $value = ( $self->value ? FALSE() : TRUE() ) ;
    }
    elsif( $self->degree == 3 ) {   # 3-value logic
        # Same truth table whether propagating or not.
        if( $self->value == UNDEF() ) {
            # It's undefined which propogates.
            $value = UNDEF() ;
        }
        elsif( $self->value == TRUE() ) {
            # It's defined and true so return false.
            $value = FALSE() ;
        }
        else {
            # It's defined and false so return true.
            $value = TRUE() ;
        }
    }
    else {                          # Multi-value logic
        $value = $self->degree - $self->value ;
    }

    $result->value( $value ) ;

    $result ;
}


DESTROY { # Object method
    ; # Noop
}


1 ;


__END__

=head1 NAME

Math::Logic - Provides pure 2, 3 or multi-value logic.

=head1 SYNOPSIS

	use Math::Logic qw( TRUE FALSE UNDEF STR_TRUE STR_FALSE STR_UNDEF ) ;
                    #      1     0    -1    'TRUE'   'FALSE'   'UNDEF'

    use Math::Logic ':NUM' ; # TRUE FALSE UNDEF -- what you normally want

	use Math::Logic ':ALL' ; # All the constants

    use Math::Logic ':STR' ; # STR_TRUE STR_FALSE STR_UNDEF

    # 2-value logic
    my $true  = Math::Logic->new( -value => TRUE,  -degree => 2 ) ;
    my $false = Math::Logic->new( -value => FALSE, -degree => 2 ) ;
    my $x     = Math::Logic->new_from_string( 'TRUE,2' ) ;

    print "true" if $true ;

    # 3-value logic (non-propagating)
    my $true  = Math::Logic->new( -value => TRUE,  -degree => 3 ) ;
    my $false = Math::Logic->new( -value => FALSE, -degree => 3 ) ;
    my $undef = Math::Logic->new( -value => UNDEF, -degree => 3 ) ;
    my $x     = Math::Logic->new_from_string( 'FALSE,3' ) ;

    print "true" if ( $true | $undef ) == TRUE ;

    # 3-value logic (propagating)
    my $true  = Math::Logic->new( -value => TRUE,  -degree => 3, -propagate => 1 ) ;
    my $false = Math::Logic->new( -value => FALSE, -degree => 3, -propagate => 1 ) ;
    my $undef = Math::Logic->new( -value => UNDEF, -degree => 3, -propagate => 1 ) ;
    my $x     = Math::Logic->new_from_string( '( UNDEF, 3, -propagate )' ) ;

    print "undef" if ( $true | $undef ) == UNDEF ;

    # multi-value logic
    my $TRUE   = 100 ; # Define our own true
    my $FALSE  = FALSE ;
    my $true   = Math::Logic->new( -value => $TRUE,  -degree => $TRUE ) ;
    my $very   = Math::Logic->new( -value => 67,     -degree => $TRUE ) ;
    my $fairly = Math::Logic->new( -value => 33,     -degree => $TRUE ) ;
    my $false  = Math::Logic->new( -value => $FALSE, -degree => $TRUE ) ;
    my $x      = Math::Logic->new_from_string( "25,$TRUE" ) ;

    print "maybe" if ( $very | $fairly ) > 50 ;

=head1 DESCRIPTION

Perl's built-in logical operators, C<and>, C<or>, C<xor> and C<not> support
2-value logic. This means that they always produce a result which is either
true or false. In fact perl sometimes returns 0 and sometimes returns undef
for false depending on the operator and the order of the arguments. For "true"
Perl generally returns the first value that evaluated to true which turns out
to be extremely useful in practice. Given the choice Perl's built-in logical
operators are to be preferred -- but when you really want pure 2-value logic
or 3-value logic or multi-value logic they are available through this module.

The only 2-value logic values are 1 (TRUE) and 0 (FALSE).

The only 3-value logic values are 1 (TRUE), 0 (FALSE) and -1 (UNDEF). Note
that UNDEF is -1 I<not> C<undef>!

The only multi-value logic values are 0 (FALSE)..<degree> -- the value of TRUE is
equal to the degree, usually 100.

Although some useful constants may be exported, this is an object module and
the results of logical comparisons are Math::Logic objects.

=head2 2-value logic

2-value logic has one simple truth table for each logical operator.

        Perl Logic      Perl Logic     Perl Logic 
    A B and  and    A B or   or    A B xor  xor
    - - ---  ---    - - --   --    - - ---  ---
    F F  F    F     F F  F    F    F F  F    F
    T T  T    T     T T  T    T    T T  F    F
    T F  F    F     T F  T    T    T F  T    T
    F T  F    F     F T  T    T    F T  T    T

      Perl Logic
    A not  not 
    - ---  ---
    F  T    T
    T  F    F

In the above tables when dealing with Perl's built-in logic T and F are any
true and any false value respectively; with Math::Logic they are objects whose
values are 1 and 0 respectively. Note that whilst Perl may return 0 or undef
for false and any other value for true, Math::Logic returns an object whose
value is either 0 (FALSE) or 1 (TRUE) only. 

    my $true   = Math::Logic->new( -value => TRUE,  -degree => 2 ) ;
    my $false  = Math::Logic->new( -value => FALSE, -degree => 2 ) ;
   
    my $result = $true & $false ; # my $result = $true->and( $false ) ;

    print $result if $result == FALSE ; 

=head2 3-value logic

3-value logic has two different truth tables for "and" and "or"; this module
supports both. In the Perl column F means false or undefined; and T, F and U
under Math::Logic are objects with values 1 (TRUE), 0 (FALSE) and -1 (UNDEF)
respectively. The + signifies propagating nulls.

        Perl  Logic        Perl  Logic         Perl  Logic 
    A B and  and+ and    A B or or+  or    A B xor  xor+ xor(same)
    - - ---  ---  ---    - - -- --   --    - - ---  ---  ---
    U U  F    U    U     U U  F  U    U    U U  F    U    U 
    U F  F    U    F     U F  F  U    U    U F  F    U    U 
    F U  F    U    F     F U  F  U    U    F U  F    U    U 
    F F  F    F    F     F F  F  F    F    F F  F    F    F
    U T  F    U    U     U T  T  U    T    U T  T    U    U
    T U  F    U    U     T U  T  U    T    T U  T    U    U
    T T  T    T    T     T T  T  T    T    T T  F    F    F
    T F  F    F    F     T F  T  T    T    T F  T    T    T
    F T  F    F    F     F T  T  T    T    F T  T    T    T

      Perl  Logic
    A not  not+ not(same)
    - ---  ---  ---
    U  T    U    U
    U  T    U    U
    F  T    T    T
    T  F    F    F

    # 3-value logic (non-propagating)
    my $true   = Math::Logic->new( -value => TRUE,  -degree => 3 ) ;
    my $false  = Math::Logic->new( -value => FALSE, -degree => 3 ) ;
    my $undef  = Math::Logic->new( -value => UNDEF, -degree => 3 ) ;

    my $result = $undef & $false ; # my $result = $undef->and( $false ) ;

    print $result if $result == FALSE ; 

    # 3-value logic (propagating)
    my $true   = Math::Logic->new( -value => TRUE,  -degree => 3, -propagate => 1 ) ;
    my $false  = Math::Logic->new( -value => FALSE, -degree => 3, -propagate => 1 ) ;
    my $undef  = Math::Logic->new( -value => UNDEF, -degree => 3, -propagate => 1 ) ;

    my $result = $undef & $false ; # my $result = $undef->and( $false ) ;

    print $result if $result == UNDEF ; 

=head2 multi-value logic

This is used in `fuzzy' logic. Typically we set the C<-degree> to 100
representing 100% likely, i.e. true; 0 represents 0% likely, i.e. false, and
any integer in-between is a probability.

The truth tables for multi-value logic work like this:

    C<and> lowest  value is the result;
    C<or>  highest value is the result;
    C<xor> highest value is the result 
           unless they're the same in which case the result is FALSE;
    C<not> degree minus the value is the result.

               Logic
     A   B  and  or xor     
    --- --- --- --- ---
      0   0   0   0   0
      0 100   0 100 100
    100   0   0 100 100
    100 100 100 100   0
      0  33   0  33  33
     33   0   0  33  33
     33 100  33 100  33
     33  33  33  33   0
    100  33  33 100 100
      0  67   0  67  67
     67   0   0  67  67
     67 100  67 100 100
     67  67  67  67   0
    100  67  67 100 100
     33  67  33  67  67
     67  33  33  67  67

     A  not  
    --- --- 
      0 100
     33  67
     67  33
    100   0
   
    # multi-value logic
    my $TRUE   = 100 ; 
    my $FALSE  = FALSE ;
    $true      = Math::Logic->new( -value => $TRUE,  -degree => $TRUE ) ;
    $very      = Math::Logic->new( -value => 67,     -degree => $TRUE ) ;
    $fairly    = Math::Logic->new( -value => 33,     -degree => $TRUE ) ;
    $false     = Math::Logic->new( -value => $FALSE, -degree => $TRUE ) ;

    my $result = $fairly & $very ; # my $result = $fairly->and( $very ) ;

    print $result if $result == $fairly ; 

=head2 Public methods

    new             class   object (also used for assignment)
    new_from_string class   object
    value                   object
    degree                  object
    propagate               object
    compatible              object
    as_string               object 
    and                     object (same as &)
    or                      object (same as |)
    xor                     object (same as ^)
    not                     object (same as !)
    ""                      object (see as_string)
    0+                      object (automatically handled)
    <=>                     object (comparisons)
    &                       object (logical and)
    |                       object (logical or)
    ^                       object (logical xor)
    !                       object (logical not)

=head2 new

    my $x = Math::Logic->new ;

    my $y = Math::Logic->new( -value => FALSE, -degree => 3, -propagate => 0 );

    my $a = $x->new ; 

    my $b = $y->new( -value => TRUE ) ;

This creates new Math::Logic objects. C<new> should never fail because it will
munge any arguments into something `sensible'.

If used as an object method, e.g. for assignment then the settings are those
of the original object unless overridden. If used as a class method with no
arguments then default values are used.

C<-degree> an integer indicating the number of possible truth values;
typically set to 2, 3 or 100 (to represent percentages). Minimum value is 2.

C<-propagate> a true/false integer indicating whether NULLs (UNDEF) should
propagate; only applicable for 3-value logic where it influences which truth
table is used. 

C<-value> an integer representing the truth value. For 2-value logic only 1
and 0 are valid (TRUE and FALSE); for 3-value logic 1, 0, and -1 are valid
(TRUE, FALSE and UNDEF); for multi-value logic any positive integer less than
or equal to the C<-degree> is valid.

=head2 new_from_string

    my $x = Math::Logic->new_from_string( '1,2' ) ;
    my $y = Math::Logic->new_from_string( 'TRUE,3,-propagate' ) ;
    my $z = Math::Logic->new_from_string( '( FALSE, 3, -propagate )' ) ;
    my $m = Math::Logic->new_from_string( '33,100' ) ;
    my $n = Math::Logic->new_from_string( '67%,100' ) ;

This creates new Math::Logic objects. The string B<must> include the first two
values, which are C<-value> and C<-degree> respectively.

=head2 value

    print $x->value ;
    print $x ;

This returns the numeric value of the object. For 2-value logic this will
always be 1 or 0; for 3-value logic the value will be 1, 0 or -1; for
multi-value logic the value will be a positive integer <= C<-degree>. 

=head2 degree

    print $x->degree ;

This returns the degree of the object, i.e. the number of possible truth
values the object may hold; it is always 2 or more.

=head2 propagate

    print $x->propagate ;

This returns whether or not the object propagates NULLs (UNDEF). For 2 or
multi-value logic always returns FALSE; for 3-value logic may return TRUE or
FALSE.

=head2 compatible

    print $x->compatible( $y ) ;

Returns TRUE or FALSE depending on whether the two object are compatible.
Objects are compatible if they have the same C<-degree> and in the case of
3-value logic the same C<-propagate>. Logical operators will only work on
compatible objects.

=head2 as_string and ""
                                    # output:
    print $x->as_string ;           # TRUE
    print $x->as_string( 1 ) ;      # (TRUE,2)
    print $x->as_string( -full ) ;  # (TRUE,2)

    print $x ;                      # TRUE
    print $x->value ;               # 1

    print $m ;                      # 33
    print $m->value ;               # 33
    print $m->as_string( 1 ) ;      # (33%,100)

Usually you won't have to bother using C<as_string> since Perl will invoke it
for you as necessary; however if you want a string that can be saved, (perhaps
to be read in using C<new_from_string> later), you can pass an argument to
C<as_string>.

=head2 and and &

    print "true" if ( $y & $z ) == TRUE ;
    print "yes"  if $y & 1 ;
    print "yes"  if TRUE & $y ;
    
    $r = $y & $z ; # Creates a new Math::Logic object with the resultant truth value

    print "true" if $y->and( $z ) == TRUE ;

Applies logical and to two objects. The truth table used depends on the
object's C<-degree> (and in the case of 3-value logic on the C<-propagate>).
(See the truth tables above.)

=head2 or and |

    print "true" if ( $y | $z ) == TRUE ;
    print "yes"  if $y | 1 ;
    print "yes"  if TRUE | $y ;
    
    $r = $y | $z ; # Creates a new Math::Logic object with the resultant truth value

    print "true" if $y->or( $z ) == TRUE ;

Applies logical or to two objects. The truth table used depends on the
object's C<-degree> (and in the case of 3-value logic on the C<-propagate>).
(See the truth tables above.)

=head2 xor and ^

    print "true" if ( $y ^ $z ) == TRUE ;
    print "yes"  if $y ^ 0 ;
    print "yes"  if TRUE ^ $y ;
    
    $r = $y ^ $z ; # Creates a new Math::Logic object with the resultant truth value

    print "true" if $y->xor( $z ) == TRUE ;

Applies logical xor to two objects. The truth table used depends on the
object's C<-degree>. (See the truth tables above.)

=head2 not and !

    print "true" if ! $y == TRUE ;
    
    $r = ! $y ; # Creates a new Math::Logic object with the resultant truth value

    print "true" if $y->not == TRUE ;

Applies logical not to the object. The truth table used depends on the
object's C<-degree>. (See the truth tables above.)

=head2 comparisons and <=>

All the standard (numeric) comparison operators may be applied to Math::Logic
objects, i.e. <, <=, >, =>, ==, != and <=>.

=head2 typecasting

The only typecasting that appears to make sense is between 2 and 3-value
logic. There is no direct support for it but it can be achieved thus:

    my $x = Math::Logic->new_from_string( '1,2' ) ;  # TRUE  2-value
    my $y = Math::Logic->new_from_string( '0,3' ) ;  # FALSE 3-value
    my $z = Math::Logic->new_from_string( '-1,3' ) ; # UNDEF 3-value

    $x3 = $x->new( -degree => 3 ) ;
    $y2 = $y->new( -degree => 2 ) ;
    $z2 = $y->new( -degree => 2 ) ; # UNDEF converted silently to FALSE

=head1 BUGS

(none known)

=head1 CHANGES

2000/02/20

First version. Ideas taken from my Math::Logic3 and (unpublished) Math::Fuzzy;
this module is intended to supercede both.

=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'logic' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the LGPL. 

=cut

