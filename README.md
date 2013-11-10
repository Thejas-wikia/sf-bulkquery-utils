# SalesForce Bulk Query Utils
Bash shell utilities for exporting CSV data from your SalesForce organization using the SalesForce Bulk Query API

### Commands
```bash
login <username> <password>
runQuery <object> <query> <output.csv>
```

### Example
```bash
source sf-bulkquery-utils.sh
login "salesforce-username" "salesforce-password"
runQuery "Account" "SELECT Name, Hours_Purchased__c FROM Account" "accounts.csv"
runQuery "Opportunity" "SELECT Name FROM Opportunity" "opportunities.csv"
```

## Authors

**Scott McLeod**

+ <http://github.com/halcyon>

## Copyright and license

Copyright (c) 2013 Scott McLeod &lt;halcyonblue@gmail.com&gt; under [the Apache 2.0 license](LICENSE).
