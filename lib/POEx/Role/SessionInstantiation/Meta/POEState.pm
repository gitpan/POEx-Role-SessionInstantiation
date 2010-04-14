package POEx::Role::SessionInstantiation::Meta::POEState;
BEGIN {
  $POEx::Role::SessionInstantiation::Meta::POEState::VERSION = '1.101040';
}

use MooseX::Declare;

#ABSTRACT: A read-only object that provides POE context

class POEx::Role::SessionInstantiation::Meta::POEState
{
    use POEx::Types(':all');
    use MooseX::Types::Moose('Maybe', 'Str');


    has sender  => ( is => 'ro', isa => Kernel|Session|DoesSessionInstantiation);
    

    has state   => ( is => 'ro', isa => Str );


    has kernel  => ( is => 'ro', isa => Kernel );


    has file    => ( is => 'ro', isa => Maybe[Str] );
    has line    => ( is => 'ro', isa => Maybe[Str] );
    has from    => ( is => 'ro', isa => Maybe[Str] );


    method clone
    {
        return $self->meta->clone_object($self);
    }
}

1;



=pod

=head1 NAME

POEx::Role::SessionInstantiation::Meta::POEState - A read-only object that provides POE context

=head1 VERSION

version 1.101040

=head1 PUBLIC_ATTRIBUTES

=head2 sender 

    is: ro, isa: Kernel|Session|DoesSessionInstantiation

The sender of the current event can be access from here. Semantically the same
as $_[+SENDER].

=head2 state

    is: ro, isa => Str

The state fired. This should match the current method name (unless of course
within the _default event handler, then it will be the event name that was 
invoked but did not exist in your object instance.

=head2 kernel

    is: ro, isa: Kernel

This is actually the POE::Kernel singleton provided as a little sugar instead
of requiring use of $poe_kernel, etc. To make sure you are currently within a 
POE context, check this attribute for definedness.

=head2 [qw/file line from/] 

    is: rw, isa: Maybe[Str]

These attributes provide tracing information from within POE. From is actually
not used in POE::Session as far as I can tell, but it is available just in 
case.

=head1 PROTECTED_METHODS

=head2 clone

Clones the current POEState object and returns it

=head1 AUTHOR

  Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas Perez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

