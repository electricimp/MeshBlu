# Meshblu
[Meshblu](https://meshblu-http.readme.io/docs/getting-started) is a machine-to-machine instant messaging network and API.  All Meshblu requests in this library are sent asyncronously and require a callback functions to receive data.

**To add this library to your project, add `#require "Meshblu.class.nut:1.0.0"` to the top of your device code.**

You can view the library’s source code on [GitHub](https://github.com/electricimp/Meshblu/tree/v1.0.0).


##Class Usage

##### Constructor
The class’ constructor takes one optional parameter (a table of properties):


| Parameter     | Type         | Default | Description |
| ------------- | ------------ | ------- | ----------- |
| properties    | table        | {}      | Properties for your Imp |


###### Meshblu UUID & Token
If you need to register your device do not include uuid or token in the properties table.  You can use the *#registerDevice* method after you initialize Meshblu.

###### Setup With Meshblu auth UUID & Token
If you have already registered your device using octoblu or nodeblu, include your *uuid* and *token* in the properties table.

###### Example Code :
```squirrel
  // set some default properties
  impID <- split(http.agenturl(), "/").pop();
  properties <- { "impID" : impID,
                "platform" : "Electric Imp",
                  "uuid" : " << your_meshblu_auth_uuid >> ",
                  "token" : " << your_meshblu_auth_token >> ",
                  "online" : true
                  };

  meshblu <- Meshblu(properties);
```
###### Setup Without Meshblu UUID & Token
If you need to register your device do not include uuid or token in the properties table.  You can use the *#registerDevice* method after you initialize Meshblu.

###### Example Code :
```squirrel
  // set some default properties
  impID <- split(http.agenturl(), "/").pop();
  properties <- { "impID" : impID,
                "platform" : "Electric Imp",
                  "online" : true
                  };

  meshblu <- Meshblu(properties);
```
## Class Methods

### registerDevice(*cb*)
The *registerDevice* method registers a device with Meshblu with the properties passed into the constructor. The callback is passed three parameters (error, Meshblu's response, Meshblu's response data in table format).  Data will include a UUID device id and security token.  Device registration is the only time the token will be given. Be sure to keep it somewhere safe as the token is required to update your device in the future. The uuid and token will be stored locally but will not persist between agent restarts.

###### Example Code :
```squirrel
  meshblu.registerDevice(function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      //you must store if you want to update device
      server.log(data.token);
      server.log(data.uuid);
    }
  });
```

### getDeviceInfo(*uuid, cb*)
The *getDeviceInfo* method requests all information (except the token) for the specified device. The callback is passed three parameters (error, Meshblu's response, Meshblu's response in table format).

###### Example Code :
```squirrel
  meshblu.getDeviceInfo("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) { server.log(err); }
    if(data) { server.log(http.jsonencode(data)); }
  });
```
### updateDevice(*newProperties, [cb]*)
The *updateDevice* method updates device. New properties must be key/value pairs.  The callback is optional and is passed three parameters (error, Meshblu's response, Meshblu's response data in table format). If request is successful Meshblu response includes the updated device info and info on the device that sent the update.

###### Example Code :
```squirrel
  local newProps = {"online" : false};
  meshblu.updateDevice(newProps, function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.online);
      server.log(data.from.uuid);
      server.log(data.from.timestamp);
    }
  });
```
### deleteDevice(*[cb]*)
The *deleteDevice* method unregisters your device from Meshblu.  The callback is optional and is passed three parameters (error, Meshblu's response, Meshblu's response data in table format). If request is successful Meshblu response includes the uuid that was deleted, and the locally stored uuid & token are deleted.

###### Example Code :
```squirrel
  meshblu.deleteDevice(function(err, response, data) {
    if(err) { server.log(err); }
    if(data) { server.log(data.uuid); }
  });
```

### getLocalDevices(*cb*)
The *getLocalDevices* method requests a list of unclaimed devices that are on the same network as the requesting resource.  The callback is passed three parameters (error, Meshblu's response, Meshblu's response data in table format).

###### Example Code :
```squirrel
  meshblu.getLocalDevices(function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      foreach(device in data.devices) {
        server.log(device.uuid);
      }
    }
  });
```

### online(*[cb]*)
The *online* method updates device's online property to true.

###### Example Code :
```squirrel
  meshblu.online(function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.online);
      server.log(data.from.timestamp);
    }
  });
```
### offline(*[cb]*)
The *offline* method updates device's online property to false.

###### Example Code :
```squirrel
  meshblu.offline(function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.online);
      server.log(data.from.timestamp);
    }
  });
```
### storeData(*data, [cb]*)
The *storeData* method stores sensor data. Data must be in formatted in key/value pairs. The callback is optional and is passed three parameters (error, Meshblu's response, Meshblu's response data). If request is successful Meshblu response is an empty string.

###### Example Code :
```squirrel
  local data = {"temp":27, "ts": 1438879428};

  meshblu.storeData(data, function(err, response, data) {
    if(err) { server.log(err); }
  });
```
### getData(*uuid, cb*)
The *getData* method requests the last 10 data updates for a specific device. The callback is passed three parameters (error, Meshblu's response, Meshblu's response data in table format). If request is successful Meshblu response includes data key/value pairs, a timestamp, and the uuid.

###### Example Code :
```squirrel
  meshblu.getData("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, d) {
    if(err) { server.log(err); }
    if(d) {
      foreach(dataPoint in d.data) {
        server.log(dataPoint.temp);
        server.log(dataPoint.uuid);
        server.log(dataPoint.timestamp);
      }
    }
  });
```
### getStreamingData(*uuid*)
The *getStreamingData* method streams data from the specificed device, if you are subscribed.  The data is received via the subscribe callback.

###### Example Code :
```squirrel
  meshblu.subscribe("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.payload.uuid);
      server.log(data.payload.temp);
      server.log(data.payload.timestamp);
    }
  });
  meshblu.getStreamingData("b11f10f4-4093-4a29-afe3-ca27970b2725");
```
### sendMessage(*device(s), message, [cb]*)
The *sendMessage* method sends a message to a specific device ("b11f10f4-4093-4a29-afe3-ca27970b2725"), array of devices (["b11f10f4-4093-4a29-afe3-ca27970b2725", "71301e1a-dd74-4f3d-b859-f468a4e88241"]), or all devices ("*") subscribing to a Meshblu uuid. The message can be a string, table, etc. The callback is optional and is passed three parameters (error, Meshblu's response, Meshblu's response data in table format).  If the request is successful Meshblu response includes devices and payload.

###### Example Code :
```squirrel
  meshblu.sendMessage("*", "hello world", function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.devices);
      server.log(data.payload);
    }
  });
```
### subscribe(*uuid, cb*)
The *subscribe* method opens a stream that returns messages as they are sent and received from the uuid specified. The callback is passed three parameters (error, Meshblu's response, Meshblu's response data in table format).

###### Example Code :
```squirrel
  meshblu.subscribe("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.fromUuid);
      server.log(http.jsonencode(data.payload));
    }
  });
```
### subscribeWithTypeFilter(*uuid, types, cb*)
The *subscribeWithTypeFilter* method opens a stream that returns messages as they are sent, received, and/or broadcast from the uuid specified. The callback is passed three parameters (error, Meshblu's response, Meshblu's response data in table format).

###### Example Code :
```squirrel
  meshblu.subscribeWithTypeFilter("b11f10f4-4093-4a29-afe3-ca27970b2725", "received", function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.fromUuid);
      server.log(http.jsonencode(data.payload));
    }
  });
```

### getNetworkStatus(*cb*)
The *getNetworkStatus* method requests the Meshblu platform status. The callback is passed three parameters (error, Meshblu's response, Meshblu's response data in table format).

###### Example Code :
```squirrel
  meshblu.getNetworkStatus(function(err, response, data) {
    if(err) { server.log(err); }
    if(data) {
      server.log(data.meshblu);
    }
  });
```

## License

Meshblu is licensed under [MIT License](./LICENSE).