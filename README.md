node-elastic-watch
==================

#install
npm install

#configure
create and condifgure config.json
example:
```
{ "accessKeyId": "XXXX", "secretAccessKey": "XXXX", "region": "us-east-1" }
```
Edit EnvironmentName in line 14, file app.coffee


#run

exec
```
coffee app.coffee
```

expected output
```
{ CPU: 0.3,
  BW: 75113,
  Timestamp: Wed Apr 09 2014 17:28:00 GMT-0300 (CLST) }
```
