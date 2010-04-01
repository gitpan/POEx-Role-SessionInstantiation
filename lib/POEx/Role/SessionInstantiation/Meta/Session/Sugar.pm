{package POEx::Role::SessionInstantiation::Meta::Session::Sugar;
$POEx::Role::SessionInstantiation::Meta::Session::Sugar::VERSION = '1.100910';}

#ABSTRACT: Provides some convenience methods for some POE::Kernel methods


role POEx::Role::SessionInstantiation::Meta::Session::Sugar
{
    use POEx::Types(':all');

    
    method post(SessionAlias|SessionID|Session|DoesSessionInstantiation $session, Str $event_name, @args) 
    {
        confess('No POE context') if not defined($self->poe->kernel);
        return $self->poe->kernel->post($session, $event_name, @args);
    }

    method yield(Str $event_name, @args)
    {
        confess('No POE context') if not defined($self->poe->kernel);
        return $self->poe->kernel->yield($event_name, @args);
    }

    method call(SessionAlias|SessionID|Session|DoesSessionInstantiation $session, Str $event_name, @args) 
    {
        confess('No POE context') if not defined($self->poe->kernel);
        return $self->poe->kernel->call($session, $event_name, @args);
    }
}

1;


=pod

=head1 NAME

POEx::Role::SessionInstantiation::Meta::Session::Sugar - Provides some convenience methods for some POE::Kernel methods

=head1 VERSION

version 1.100910

=head1 PUBLIC_METHODS

=head2 [qw/post yield call/]

These are provided as sugar for the respective POE::Kernel methods.

=head1 AUTHOR

  Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas Perez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
