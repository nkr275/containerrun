/api/health/notifications
/api/health/iam
/api/health/aggregator
/api/health/communicator
/api/health/console
/api/health/alert
/api/health/metricquery
/api/health/metricingest
/api/health/lcm
/api/health/devicemgmt
/api/health/devicesec
/api/health/discovery           http://$devicedisc:60069
/api/health/repo
/api/health/distribution
/api/health/zcsconnector
/api/health/deviceagent

curl -L -X GET 'http://nginx/api/health/notifications' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
(Service notifications is healthy)
curl -L -X GET 'http://nginx/api/health/iam' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service iam is healthy
curl -L -X GET 'http://nginx/api/health/aggregator' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
502 Bad Gateway iotc-aggregator-7f7497f84f-6l8ww   CrashLoopBackOff

curl -L -X GET 'http://nginx/api/health/console' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service console is healthy

curl -L -X GET 'http://nginx/api/health/alert' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
502 Bad Gateway

*************
not getting any responce through localhost also
*************
curl -L -X GET 'http://nginx/api/health/metricquery' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service iotc-metricquery is healthy


curl -L -X GET 'http://nginx/api/health/metricingest' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"status":"OK","description":"MetricIngest uService is healthy.","checks":{"checks":null}}

curl -L -X GET 'http://nginx/api/health/lcm' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service lcm is healthy

curl -L -X GET 'http://nginx/api/health/devicemgmt' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service devicemgmt is healthy

curl -L -X GET 'http://nginx/api/health/devicesec' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service devicesec is healthy.

curl -L -X GET 'http://nginx/api/health/discovery' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service devicedisc is healthy.

curl -L -X GET 'http://nginx/api/health/repo' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

Service repo is healthy.

curl -L -X GET 'http://nginx/api/health/distribution' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

Service distribution is healthy

curl -L -X GET 'http://nginx/api/health/deviceagent' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"
Service deviceagent is healthy


**********************************************************************************************
**IOTC-IAM all api** 

curl -L -X GET 'http://nginx/api/certificates' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"certificates":[],"pageInfo":{"totalPages":0,"page":1,"pageSize":10,"totalElements":0}}

curl -L -X GET 'http://nginx/api/auth' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

Unknown internal server error

curl -L -X GET 'http://nginx/api/permissions' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"permissions":[{"name":"CREATE_ORGANIZATION","description":"Create Organization","permissionNumber":1},{"name":"DELETE_ORGANIZATION","description":"Delete Organization","permissionNumber":2},{"name":"VIEW_ORGANIZATION","description":"View Organization","permissionNumber":3},{"name":"EDIT_ORGANIZATION","description":"Edit Organization","permissionNumber":4},{"name":"CREATE_USER","description":"Create User","permissionNumber":5}, 
even more 

curl -L -X GET 'http://nginx/api/groups' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"groups":[{"name":"System Administrators","description":"System Administrators","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"createdBy":"c624a3a3-5247-4bcd-95ba-554fed1d4307","lastUpdatedBy":"c624a3a3-5247-4bcd-95ba-554fed1d4307","id":"4d559c5a-6680-41f9-8d0a-56e42cf01169"},{"name":"Organization Administrators","description":"Organization Administrators","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"createdBy":"c624a3a3-5247-4bcd-95ba-554fed1d4307","lastUpdatedBy":"c624a3a3-5247-4bcd-95ba-554fed1d4307","id":"c758a990-1074-4478-b677-e9cbbde1281a"}],"pageInfo":{"totalPages":1,"page":1,"pageSize":10,"totalElements":2}}


curl -L -X GET 'http://nginx/api/roles' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"roles":[{"name":"Alert Administrator","description":"Can view and acknowledge alerts","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"1628d1fa-cb75-43c8-865d-4572623041d3"},{"name":"Identity and Access Administrator","description":"Can add/modify organization, users, groups, roles, notifications, and view audit logs.","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"3afd585f-194b-44c4-95ac-a355134ec597"},{"name":"Device Administrator","description":"Can add/modify device and device templates","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"862690e7-21c3-4098-900e-63af0dfd4bac"},{"name":"Insights Viewer","description":"Can view dashboards and insights","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"9181510e-7cc6-401d-ad89-c8582bf3395c"},{"name":"Gateway Administrator","description":"Can add devices to system","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"9427db88-6227-4af6-8532-2ec93ffd3b3c"},{"name":"Package Administrator","description":"Can add/modify packages.","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"e7f91dd6-e9a3-4b3e-af3b-61971450a53b"},{"name":"Monitoring Administrator","description":"Can modify alerts, notification definitions, notification destinations and view metrics.","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"ef5d902c-ea34-4d37-9b0e-cba72087170d"},{"name":"Campaign Administrator","description":"Can add/modify campaigns, packages and view notification definitions, notification destinations.","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"f37893cf-f2fd-482b-9ca9-88291ec098d1"}],"pageInfo":{"totalPages":1,"page":1,"pageSize":10,"totalElements":8}}

curl -L -X GET 'http://nginx/api/users' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"users":[{"userName":"sysadmin@infer.local","email":"ajith@smarthub.ai","displayName":"sysadmin","status":"ACTIVE","type":"basic","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"id":"c624a3a3-5247-4bcd-95ba-554fed1d4307"}],"pageInfo":{"totalPages":1,"page":1,"pageSize":10,"totalElements":1}}


curl -L -X GET 'http://nginx/api/organizations' --header 'Accept:application/json;api-version=0.17' --header "Authorization: Bearer $infer_token"

{"tenants":[{"name":"smarthub","domainName":"smarthub.local","parentId":null,"status":"ACTIVE","orgId":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc","createdTime":1625800031729,"lastUpdatedTime":1625800031729,"updateVersion":1,"createdBy":"c624a3a3-5247-4bcd-95ba-554fed1d4307","lastUpdatedBy":"c624a3a3-5247-4bcd-95ba-554fed1d4307","ancestors":null,"id":"b2f1b750-1fee-4b4e-a92a-375e39a5b4fc"}],"pageInfo":{"totalPages":1,"page":1,"pageSize":10,"totalElements":1}}

*********************************************************************************************