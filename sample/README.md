
This is sample app using `CatalystX::Eta::` Roles as CRUD.

Deps with binary deps:

    DBD::Pg         - PostgreSQL
    App::Sqitch

How to test this app:

    $ cpanm --installdeps .

    $ createdb youapp_dev

    Open the file sqitch.conf and configure it to look like the below:

    [core "pg"]
        # client = psql
        username = postgres
        password = in-postgres-we-trust
        db_name =  youapp_dev
        host = 127.0.0.1


    $ sqitch deploy

    $ prove -I ../catalystX-eta/lib/ -lvr t/

If you have `forkprove` installed:

    forkprove -I ../catalystX-eta/lib/ -MMyApp -j8 -lvr t/

    # you may want change -j8 to something else!

To tidy all code:

    tidyall -a

