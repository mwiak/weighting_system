make the following reworks:

## database schema and models:
- database now have unnecessary columns, and some new changes will be added.

### clients and suppliers:
- now a separate table should be implemented for suppliers and clients
- we do not need all current info about clients and suppliers, only include, name, telephone number, and city. all other columns need to be deleted.

### weighting_tabs:
make the folloiwng changes:
- there is no need for loading/offloading operation type.
- tare,gross, and net weight should be integers not doubles.


### Important Note:
currently, the app is dependent on this schema, so adjust the dependeices across the pages, services, providers, widgets, and models, to reflect the new changes.