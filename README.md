# Meshblu v1.1.0

[Meshblu](https://meshblu-http.readme.io/docs/getting-started) is a machine-to-machine instant messaging network and API.

**To add this library to your project, add `#require "Meshblu.class.nut:1.1.0"` to the top of your device code.**

You can view the library’s source code on [GitHub](https://github.com/electricimp/Meshblu/tree/v1.1.0).

## Class Usage

### Callbacks

All requests made to the MeshBlu are done asynchronously, and take an optional callback parameter. The callback function should take three parameters: *err*, *resp*, and *data*.

- **err**: A string describing the error, or `null` if the request was successful.
- **resp**: The [HTTP response table](https://electricimp.com/docs/api/httprequest/sendasync).
- **data**: The decoded body of the HTTP request.

### Constructor: Meshblu(*[properties]*)

The class’ constructor takes one optional parameter (a table of properties):

| Parameter     | Type         | Default | Description             |
| ------------- | ------------ | ------- | ----------------------- |
| properties    | table        | { }     | Properties for your imp |

#### Setup an unregistered device
If you need to register your device do not include the "uuid" or "token" keys in your properties table. You can use the *[registerDevice](#registerdevicecb)* method after you initialize Meshblu.

```squirrel
// set some default properties
impID <- split(http.agenturl(), "/").pop();
properties <- {
    "impID" : impID,
    "platform" : "Electric Imp",
    "online" : true
};

// Create the device object
meshblu <- Meshblu(properties);

// register the device
// (see registerDevice() below..)
```

#### Setup a pre-registered device
If you have already registered your device using octoblu or nodeblu, include your *uuid* and *token* in the properties table.

```squirrel
// set some default properties
impID <- split(http.agenturl(), "/").pop();

properties <- {
    "impID" : impID,
    "platform" : "Electric Imp",
    "uuid" : "<-- AUTH_ID -->",
    "token" : "<-- AUTH_TOKEN -->",
    "online" : true
};

// Create the device object
meshblu <- Meshblu(properties);

// Sync local and Meshblu properties
// (see updateDevice(properties) below)
```

## Class Methods

### registerDevice(*cb*)
The *registerDevice* method registers a device with Meshblu with the properties passed into the constructor.

**NOTE:** The data passed to the callback will include a `uuid` key, and a `token` key. **Device registration is the only time the token will be given.** Be sure to keep it somewhere safe as the token is required to update your device in the future. The uuid and token will be stored locally but will not persist between agent restarts (upon receiving the uuid and token, you should store the values externally in a database, or using the agent's [server.save](https://electricimp.com/docs/api/server/save) and [server.load](https://electricimp.com/docs/api/server/save) methods).

```squirrel
deviceData <- server.load();

// Register the device if we don't have a uuid or token:
if (!("uuid" in deviceData && "token" in deviceData)) {
    meshblu.registerDevice(function(err, response, data) {
        if(err) {
            server.log(err);
            return;
        }

        // you must store if you want to update device
        deviceData.token <- data.token;
        deviceData.uuid <- data.uuid;
        server.save(deviceData);
    });
}
```

### getDeviceCredentials()
The *getDeviceCredentials* method returns the device's locally stored credentials. If there are no stored credentials, this methods returns null.

```squirrel
local creds = meshblu.getDeviceCredentials();
if (creds) {
    server.log(http.jsonencode(creds));
} else {
    server.log("No credentials");
}
```

### setDeviceCredentials(*uuid, token*)
The *setDeviceCredentials* method stores the uuid and token locally.

```squirrel
meshblu.setDeviceCredentials("b11f10f4-4093-4a29-afe3-ca27970b2725", "c6be147fcc21df7c8c756b0fca0a2caf04a9b0e0");

local creds = meshblu.getDeviceCredentials();
server.log(http.jsonencode(creds));
```

### getDeviceInfo(*uuid, cb*)
The *getDeviceInfo* method requests all information (except the token) for the specified device.

```squirrel
meshblu.getDeviceInfo("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }
    server.log(http.jsonencode(data));
});
```

### updateDevice(*newProperties, [cb]*)
The *updateDevice* method updates device. New properties must be key/value pairs. If request is successful Meshblu response includes the updated device info and info on the device that sent the update.

```squirrel
local newProps = {"online" : false};
meshblu.updateDevice(newProps, function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.online);
    server.log(data.from.uuid);
    server.log(data.from.timestamp);
});
```
### deleteDevice(*[cb]*)
The *deleteDevice* method unregisters your device from Meshblu. If request is successful Meshblu response includes the uuid that was deleted, and the locally stored uuid & token are deleted.

```squirrel
meshblu.deleteDevice(function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.uuid);
});
```

### getLocalDevices(*cb*)
The *getLocalDevices* method requests a list of unclaimed devices that are on the same network as the requesting resource.

```squirrel
meshblu.getLocalDevices(function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }
    foreach(device in data.devices) {
        server.log(device.uuid);
    }
});
```

### online(*[cb]*)
The *online* method updates device's online property to true.

```squirrel
meshblu.online(function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.online);
    server.log(data.from.timestamp);
});
```

### offline(*[cb]*)
The *offline* method updates device's online property to false.

```squirrel
meshblu.offline(function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.online);
    server.log(data.from.timestamp);
});
```

### storeData(*data, [cb]*)
The *storeData* method stores sensor data. Data must be in formatted in key/value pairs. If request is successful Meshblu response is an empty string.

```squirrel
local data = {"temp":27, "ts": 1438879428};

meshblu.storeData(data, function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }
    if(data == "") {
        server.log("Data Stored");
    }
});
```

### getData(*uuid, cb*)
The *getData* method requests the last 10 data updates for a specific device. If request is successful Meshblu response includes data key/value pairs, a timestamp, and the uuid.

```squirrel
meshblu.getData("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }
    foreach(dataPoint in data.data) {
        server.log(dataPoint.temp);
        server.log(dataPoint.uuid);
        server.log(dataPoint.timestamp);
    }
});
```

### getStreamingData(*uuid*)
The *getStreamingData* method streams data from the specificed device, if you are subscribed. The data is received via the subscribe callback.

```squirrel
meshblu.subscribe("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.payload.uuid);
    server.log(data.payload.temp);
    server.log(data.payload.timestamp);
});

meshblu.getStreamingData("b11f10f4-4093-4a29-afe3-ca27970b2725");
```

### sendMessage(*device(s), message, [cb]*)
The *sendMessage* method sends a message to a specific device ("b11f10f4-4093-4a29-afe3-ca27970b2725"), array of devices (["b11f10f4-4093-4a29-afe3-ca27970b2725", "71301e1a-dd74-4f3d-b859-f468a4e88241"]), or all devices ("*") subscribing to a Meshblu uuid. The message can be a string, table, etc. If the request is successful Meshblu response includes devices and payload.

```squirrel
// broadcast a message to all devices
meshblu.sendMessage("*", "hello world", function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.devices);
    server.log(data.payload);
});
```

### subscribe(*uuid, cb*)
The *subscribe* method opens a stream that returns messages as they are sent and received from the uuid specified.
The *data* returned is an array of events.

```squirrel
meshblu.subscribe("b11f10f4-4093-4a29-afe3-ca27970b2725", function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.fromUuid);
    server.log(http.jsonencode(data.payload));
});
```

### subscribeWithTypeFilter(*uuid, types, cb*)
The *subscribeWithTypeFilter* method opens a stream that returns messages as they are sent, received, and/or broadcast from the uuid specified.
The *data* returned is an array of events.

```squirrel
meshblu.subscribeWithTypeFilter("b11f10f4-4093-4a29-afe3-ca27970b2725", "received", function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    foreach (event in data) {
        if ("payload" in event) {
            server.log(event.fromUuid + " says: " + http.jsonencode(event.payload));
        }
    }
});
```

### getNetworkStatus(*cb*)
The *getNetworkStatus* method requests the Meshblu platform status.

```squirrel
meshblu.getNetworkStatus(function(err, response, data) {
    if(err) {
        server.log(err);
        return;
    }

    server.log(data.meshblu);
});
```

# License

Meshblu is licensed under [MIT License](./LICENSE).
