# WTF CatalystX::Eta is and why did you do that

I started (although not with this name) as set of Catalyst Controller Roles to extend and reduce repeatable tasks I had to do to make REST/CRUD stuff.

More later, I had to start many Catalyst projects. Then, I started teaching others collaborators how to use it on their projects.
After a while, they made some modifications on they ::Roles project, but does not pass all ::Roles. So, I'm using this namespace to group and keep those changes together.

This module may not fit for you, but it's a very simple way to make CRUD schemas on REST, without prohibit or complicate use of catalyst power, like chains or anything else.

# Depends on...

In order to extends `CatalystX::Eta::Controller::AutoObject` you need need `/error_404`  Catalyst Private action defined.

`CatalystX::Eta::Controller::SimpleCRUD` and  `CatalystX::Eta::Controller::AssignCollection` extends `CEC::AutoObject`, so you will need in a way, or in another.

`CatalystX::Eta::Controller::REST` extends `Catalyst::Controller::REST` and make errors from `DBIx::Class::Exception` more 'api friendly' than HTML with '(en) Please come back later\n...'

All your controllers should extends `CatalystX::Eta::Controller::REST`.

`EtaMu::TraitFor::Controller::TypesValidation` add validate_request_params use `Moose::Util::TypeConstraints::find_or_parse_type_constraint` so you can do things like:

        $self->validate_request_params(
            $c,
            extra_days => {
                type     => 'Int',
                required => 0,
            },
            credit_card_id => {
                type     => 'Int',
                required => 0,
            },
        );

on your controllers, and it does the $c->status_bad_request or $c->detach for you.

More docs comming later!

