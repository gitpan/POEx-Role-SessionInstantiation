package POEx::Role::SessionInstantiation::Meta::Session::Implementation;
BEGIN {
  $POEx::Role::SessionInstantiation::Meta::Session::Implementation::VERSION = '1.102610';
}

#ABSTRACT: Provides actual POE::Session implementation

use MooseX::Declare;

role POEx::Role::SessionInstantiation::Meta::Session::Implementation {
    use POE;
    use MooseX::Types;
    use POEx::Types(':all');
    use MooseX::Types::Moose(':all');
    use POEx::Role::SessionInstantiation::Meta::POEState;

    use aliased 'POEx::Role::Event';
    use aliased 'POEx::Role::SessionInstantiation::Meta::POEState';

    requires '_clone_self';


    has heap =>
    (
        is => 'rw',
        isa => Any,
        default => sub { {} },
        lazy => 1,
    );


    has options =>
    (
        is => 'rw',
        isa => HashRef,
        default => sub { {} },
        lazy => 1,
    );


    has poe =>
    (
        is => 'rw',
        isa => class_type(POEState),
        lazy_build => 1,
    );

    method _build_poe {
        return POEState->new();
    }


    has args =>
    (
        is => 'rw',
        isa => ArrayRef,
        default => sub { [] },
        lazy => 1
    );


    has alias =>
    (
        is => 'rw',
        isa => Str,
        trigger => sub
        { 
            # we need to check to make sure we are currently in a POE context
            return if not defined($_[0]->poe->kernel);
            $_[0]->poe->kernel->alias_set($_[1]); 
        },
        clearer => '_clear_alias',
    );
    
    method clear_alias {
        # we need to check to make sure we are currently in a POE context
        return if not defined($self->poe->kernel);
        $self->poe->kernel->alias_remove($self->alias()) if $self->alias;
        $self->_clear_alias();
    }


    has ID =>
    (
        is => 'ro',
        isa => Int,
        default => sub { $POE::Kernel::poe_kernel->ID_session_to_id($_[0]) },
        lazy => 1,
    );


    method _invoke_state(Kernel|Session|DoesSessionInstantiation $sender, Str $state, ArrayRef $etc, Maybe[Str] $file, Maybe[Int] $line, Maybe[Str] $from) {
        my $method = $self->meta->find_method_by_name($state) || $self->meta->find_method_by_name('_default');

        if(defined($method))
        {
            if($method->isa('Class::MOP::Method::Wrapped'))
            {
                my $orig = $method->get_original_method;
                if(!$orig->meta->isa('Moose::Meta::Class') || !$orig->meta->does_role('POEx::Role::Event'))
                {
                    POE::Kernel::_warn($self->ID, " -> $state [WRAPPED], called from $file at $line, exists, but is not marked as an available event");
                    return;
                }
            }
            elsif(!$method->meta->isa('Moose::Meta::Class') || !$method->meta->does_role('POEx::Role::Event'))
            {
                POE::Kernel::_warn($self->ID, " -> $state, called from $file at $line, exists, but is not marked as an available event");
                return;
            }

            my $saved;
            if(defined($self->poe->kernel))
            {
                $saved = $self->poe->clone();
            }
            
            my $poe = POEState->new
            (
                sender => $sender,
                state => $state,
                file => $file,
                line => $line,
                from => $from,
                kernel => $POE::Kernel::poe_kernel
            );

            $self->poe($poe);

            POE::Kernel::_warn($self->ID(), " -> $state (from $file at $line)\n" )
                if $self->options->{trace};

            my $return = $method->execute($self, ($method->name eq '_default' ? $etc : @$etc));
            
            if(defined($saved))
            {
                $self->poe($saved);
            }
            else
            {
                $self->clear_poe();
            }

            return $return;

        }
        else
        {
            my $loggable_self = defined($self->alias) ? $self->alias : $self->ID;
            POE::Kernel::_warn
            (
                "a '$state' event was sent from $file at $line to $loggable_self ",
                "but $loggable_self has neither a handler for it ",
                "nor one for _default\n"
            );

            return undef;
        }
    }


    method _register_state (Str $method_name, Maybe[CodeRef|MooseX::Method::Signatures::Meta::Method] $coderef, Maybe[Str] $ignore) {
        # per instance changes
        $self = $self->_clone_self();

        if(!defined($coderef))
        {
            # we mean to remove this method
            $self->meta()->remove_method($method_name);
        }
        else
        {
            # horrible hack to make sure wheel states get called how they want to be called
            if($method_name =~ /POE::Wheel/)
            {
                $coderef = $self->_wheel_wrap_method($coderef);
            }
            # otherwise, it is either replace it or add it
            my $method = $self->meta()->find_method_by_name($method_name);

            if(defined($method))
            {
                $self->meta()->remove_method($method_name);
            }
            
            my ($new_method, $superclass);

            if(blessed($coderef) && $coderef->isa('MooseX::Method::Signatures::Meta::Method'))
            {
                $new_method = $coderef;
                $superclass = 'MooseX::Method::Signatures::Meta::Method';
                
                if($new_method->isa('Moose::Meta::Class') && $new_method->does_role(Event))
                {
                    $self->meta->add_method($method_name, $new_method);
                    return;
                }

            }
            else
            {
                $superclass = 'Moose::Meta::Method';
                $new_method = Moose::Meta::Method->wrap
                (
                    $coderef, 
                    (
                        name => $method_name,
                        package_name => ref($self)
                    )
                );
            }
            
            my $anon = Moose::Meta::Class->create_anon_class
            (
                superclasses => [ $superclass ],
                roles => [ Event ],
                cache => 1,
            );

            bless($new_method, $anon->name);
 
            $self->meta->add_method($method_name, $new_method);

        }
    }


    # Note: this is a horrible hack.
    method _wheel_wrap_method (CodeRef|MooseX::Method::Signatures::Meta::Method $ref) {
        sub
        {
            my $obj = shift;
            my $poe = $obj->poe;
            my @args;
            (
                $args[OBJECT] , 
                $args[SESSION], 
                $args[KERNEL], 
                $args[HEAP], 
                $args[STATE],
                $args[SENDER], 
                $args[6], 
                $args[CALLER_FILE], 
                $args[CALLER_LINE], 
                $args[CALLER_STATE],
                $args[ARG0],
                $args[ARG1],
                $args[ARG2],
                $args[ARG3],
                $args[ARG4],
                $args[ARG5],
                $args[ARG6],
                $args[ARG7],
                $args[ARG8],
                $args[ARG9],
            ) = ($obj, $obj, $poe->kernel, $obj->heap, $poe->state, $poe->sender, undef, $poe->file, $poe->line, $poe->from, @_);

            return $ref->(@args);
        }
    }
}

1;



=pod

=head1 NAME

POEx::Role::SessionInstantiation::Meta::Session::Implementation - Provides actual POE::Session implementation

=head1 VERSION

version 1.102610

=head1 PUBLIC_ATTRIBUTES

=head2 options

    is: rw, isa: HashRef, default: {}, lazy: yes

In following the POE::Session API, sessions can take options that do various
things related to tracing and debugging. By default, tracing => 1, will turn on
tracing of POE event firing to your object. debug => 1, currently does nothing 
but more object level tracing maybe enabled in future versions.

=head2 args

    is: rw, isa: ArrayRef, default: [], lazy: yes

POE::Session's constructor provides a mechanism for passing arguments that will
end up as arguments to the _start event handler. This is the exact same thing.

=head2 alias

    is: rw, isa: Str, clearer: clear_alias, trigger: registers alias

This attribute controls your object's alias to POE. POE allows for more than
one alias to be assigned to any given session, but this attribute only assumes
a single alias and will not attempt to keep track of all the aliases. Last 
alias set will be what is returned. Calling the clearer will remove the last 
alias set from POE and unset it. You must be inside a valid POE context for the
trigger to actually fire (ie, inside a event handler that has been invoked from
POE). While this can be set at construction time, it won't be until _start that
it will actually register with POE. If you override _start, don't forget to set
this attribute again ( $self->alias($self->alias); ) or else your alias will 
never get registered with POE.

=head2 ID 

    is: ro, isa: Int

This attribute will return what your POE assigned Session ID is. Must only be
accessed after your object has been fully built (ie. after any BUILD methods).
This ID can be used, in addition to a reference to yourself, and your defined
alias, by other Sessions for addressing events sent through POE to your object.

=head1 PROTECTED_ATTRIBUTES

=head2 heap

    is: rw, isa: Any, default: {}, lazy: yes  

A traditional POE::Session provides a set aside storage space for the session
context and that space is provided via argument to event handlers. With this 
Role, your object gains its own heap storage via this attribute.

=head2 poe

    is: ro, isa: POEx::Role::SessionInstantiation::Meta::POEState

The poe attribute provides runtime context for your object methods. It contains
an POEState object with it's own attributes and methods. Runtime context is 
built for each individual event handler invocation and then torn down to avoid
context crosstalk. It is important to only access this attribute from within a 
POE invoked event handler. Please see
POEx::Role::SessionInstantiation::Meta::POEState for information regarding its
methods and attributes.

=head1 PRIVATE_METHODS

=head2 _invoke_state

    (Kernel|Session|DoesSessionInstantiation $sender, Str $state, ArrayRef $etc, Maybe[Str] $file, Maybe[Int] $line, Maybe[Str] $from)

_invoke_state is the dispatch method called by POE::Kernel to deliver events. 
It will introspect via meta to find the $state given by the Kernel. If the
method exists, but doesn't compose the POEx::Role::Event role, a warning will
be issued, and the method /not/ executed. If the method doesn't exist, it will
search for a method call '_default' (which also must be marked as an event). If
it can't find that, it gives up with a warning.

Otherwise, it will build a POEState object, and then execute the method passing
@$etc as arguments. In the case of '_default', $etc will be passed as is.

=head2 _register_state

    (Str $method_name, Maybe[CodeRef|MooseX::Method::Signatures::Meta::Method] $coderef, Maybe[Str] $ignore)

_register_state is called by the Kernel anytime an event is added to a session
via POE::Kernel's state() method. This can happen from an arbitrary source or
from within the session itself via POE::Wheel instances.

POE::Wheels register plain old code refs that must be wrapped appropriately.
Otherwise it expects fullblown methods that compose POEx::Role::Event.

=head2 _wheel_wrap_method

    (CodeRef|MooseX::Method::Signatures::Meta::Method $ref)

_wheel_wrap_method is a private method that makes sure wheel states are called
how they think they should be called. This allows proper interaction with the
default POE Wheel implementations.

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas Perez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
