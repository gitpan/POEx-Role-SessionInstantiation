{package POEx::Role::SessionInstantiation::Meta::Session::Events;}

#ABSTRACT: Provides default events such as _start, _stop, etc

use MooseX::Declare;

role POEx::Role::SessionInstantiation::Meta::Session::Events
{
    use POEx::Types(':all');
    use aliased 'POEx::Role::Event';


    method _start is Event
    {
        if($self->alias)
        {
            # inside a poe context now, so fire the trigger
            $self->alias($self->alias);
        }
        1;
    }


    method _stop() is Event
    { 
        $self->clear_alias();
        1;
    }


    method _default(ArrayRef $args?) is Event
    {
        my $string = defined($self->alias) ? $self->alias : $self->ID;
        my $state = $self->poe->state;
        warn "Nonexistent '$state' event delivered to $string";
    }


    method _child(Str $event, Session|DoesSessionInstantiation $child, Any $ret?) is Event
    {
        1;
    }


    method _parent(Session|DoesSessionInstantiation|Kernel $previous_parent, Session|DoesSessionInstantiation|Kernel $new_parent) is Event
    {
        1;
    }
}

1;




=pod

=head1 NAME

POEx::Role::SessionInstantiation::Meta::Session::Events - Provides default events such as _start, _stop, etc

=head1 VERSION

version 0.092670

=head1 METHODS

=head2 _start

Provides a default _start event handler that will be invoked from POE once the
Session is registered with POE. The default method only takes the alias 
attribute and sets it again to activate the trigger. If this is overridden, 
don't forget to set the alias again so the trigger can execute.



=head2 _stop()

Provides a default _stop event handler that will be invoked from POE once the 
Session's refcount from within POE has reached zero (no pending events, no
event sources, etc). The default method merely clears out the alias.



=head2 _default(ArrayRef $args)

Provides a _default event handler to catch any POE event invocations that your
instance does not actually have. Will 'warn' about the nonexistent state. A big
difference from POE::Session is that the state and arguments are not rebundled 
upon invocation of this event handler. Instead the attempted state will be
available in the poe attribute, but the arguments are still bundled into a 
single ArrayRef



=head2 _child(Str $event, Session $child, Any $ret?)

Provides a _child event handler that will be invoked when child sesssions are
created, destroyed or reassigned to or from another parent. See POE::Kernel for
more details on this event and its semantics



=head2 _parent(Session $previous_parent, Session $new_parent)

Provides a _parent event handler. This is used to notify children session when
their parent has changes. See POE::Kernel for more details on this event.



=head1 AUTHOR

  Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Nicholas Perez.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut 



__END__
