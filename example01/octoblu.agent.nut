#require "Meshblu.class.nut:1.1.0"


// Store reading to Meshblu
function postReading(reading) {
    // Note: reading is the data passed from the device, 
    // i.e. a Squirrel table with the keys 'temp' & 'humid'
    meshblu.sendMessage("*", { "reading" : reading });
    meshblu.storeData(reading, function(err, response, data) {
        if (err) return server.error(err);
    });
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
        if (err) return server.error(err);
        
        if (typeof data == "array") {
            foreach (event in data) {
                if ("fromUuid" in event) {
                    server.log(event.fromUuid + " says: " + http.jsonencode(event));
                } else if ("error" in event) {
                    server.error("Subscribe error: " + event.error);
                    if (event.error == "Device not found") {
                        resetDeviceData();
                        server.restart();
                    }
                    return;
                } else {
                    return server.error("No fromUuid: " + http.jsonencode(event));
                }
    
                // Look for a json encoded payload
                if ("payload" in event && typeof event.payload == "string") {
                    try {
                        event.payload = http.jsondecode(event.payload);
                    } catch (e) {
                        // Don't worry, it's just not what we are looking for
                    }
                }
                
                // Look for a trigger with the new reading interval
                if ("payload" in event && typeof event.payload == "table") {
                    if ("readingInt" in event.payload) {
                        device.send("readingInt", event.payload.readingInt);
                    }
                }

            }
        }

    });

    // Ask for a stream of my own data
    meshblu.getStreamingData(deviceData.uuid);

    // Broadcast a message
    meshblu.sendMessage("*", "ready");

}


function loadDeviceData() {
    // Get stored credentials
    deviceData <- {};
    local data = server.load();
    foreach (key in ["uuid", "token"]) {
        if (key in data) {
            deviceData[key] <- data[key];
        }
    }
}

function saveDeviceData(uuid, token) {
    // Update the stored credentials
    deviceData.uuid <- uuid;
    deviceData.token <- token;
    server.save(deviceData);
}

function resetDeviceData() {
    // Reset the stored credentials
    delete deviceData.uuid;
    delete deviceData.token;
    server.save(deviceData);
}

// Set up some basic properties for Meshblu Device
properties <- {
    "impID" : imp.configparams.deviceid,
    "platform" : "Electric Imp",
    "online" : true
};

// Create a Meshblu instance
meshblu <- Meshblu(properties);

// Register the device with meshblu or set local meshblu credentials
loadDeviceData();
if ("uuid" in deviceData && "token" in deviceData) {
    // Load the existing registration
    meshblu.setDeviceCredentials(deviceData.uuid, deviceData.token);

    // Done initialising, now start
    ready();
} else {
    // Register a new device
    meshblu.registerDevice(function(err, response, data) {
        if (err) return server.error(err);

        // you must store if you want to update device
        saveDeviceData(data.uuid, data.token)

        // Done initialising, now start
        ready();
    });
}

