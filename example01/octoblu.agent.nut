#require "Meshblu.class.nut:1.1.0"


// Store reading to Meshblu
function postReading(reading) {
    // Note: reading is the data passed from the device, ie.
    // a Squirrel table with the keys 'temp' & 'humid'
    meshblu.storeData(reading, function(err, response, data) {
        if(err) {
            server.log(err);
            return;
        }
        if(data == "") {
            server.log("Data Stored");
        }
    });

    // Log the readings locally
    server.log(http.jsonencode(reading));
}


// Wait for device setup/registration to complete
// Subscribe & Stream data
// If message with new Reading Interval arrives update device's Reading Interval
function ready() {

    server.log("Ready: " + http.jsonencode(deviceData));

    // Listen for readings from the device
    device.on("reading", postReading);

    // Subscribe to messages for my device
    meshblu.subscribeWithTypeFilter(deviceData.uuid, ["received", "broadcast"], function(err, rawData, data) {
        if (err) {
            server.error(err);
            return;
        }
        
        if (typeof data == "array") {
            foreach (event in data) {
                server.log(event.fromUuid + " says: " + http.jsonencode(event));

                if("payload" in event && "readingInt" in event.payload) {
                    device.send("readingInt", event.payload.readingInt);
                }

            }
        } else {
            server.error("Invalid event")
        }

    });

    // Ask for a stream of my own data
    meshblu.getStreamingData(deviceData.uuid);

    // Broadcast a message
    meshblu.sendMessage("*", "ready");

}



// Set up some basic properties for Meshblu Device
impID <- split(http.agenturl(), "/").pop();
properties <- {
    "impID" : impID,
    "platform" : "Electric Imp",
    "online" : true,
    "topic" : ["temperature", "humidity"]
};

// Create a Meshblu instance
meshblu <- Meshblu(properties);

// Get stored credentials
deviceData <- server.load();

// Register the device with meshblu or set local meshblu credentials
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
        ready();
    });
} else {
    meshblu.setDeviceCredentials(deviceData.uuid, deviceData.token);
    ready();
}

