Compare-Groups
==============

PowerShell script to compare groups between on-prem AD and Azure AD. Currently coded to work for my environment.

Running
-------

Currently will run from both the commandline via the -groupSMTP parameter and will also prompt the user for the SMTP address if the parameter is not specified.

Requirements
------------

Must be connected to Exchange Online for the groups to be queriable. Currently the script will **not** invoke this for you, so you must be connected prior to running the script. It will notify you of this prior to beginning the work so you can cancel it if necessary.

Caveats
-------

If a member of the on-prem AD group doesn't have an SMTP address specified, they will crash the Compare-Object code. As a result, such accounts are flagged, written to the console, and then the code simply exists sans comparison.
