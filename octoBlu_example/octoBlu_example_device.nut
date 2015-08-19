// Device Code
#require "Si702x.class.nut:1.0.0"

// Instance the Si702x and save a reference in tempHumidSensor
hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
local tempHumidSensor = Si702x(hardware.i2c89);

// Configure the LED (on pin 2) as digital out with 0 start state
local led = hardware.pin2;
led.configure(DIGITAL_OUT, 0);

// Number of seconds to sleep between readings
local readingInterval = 300;

// This function will be called regularly to take temperature & humidity
// readings and log it to the device’s agent
function takeReading() {
    tempHumidSensor.read(function(reading) {
        local data = {};
        data.temp <- reading.temperature;
        data.humid <- reading.humidity;

        // Send data to the agent
        agent.send("reading", data);

        // Flash the LED to show we've taken a reading
        flashLed();

        // Wait then take another reading
        imp.wakeup(readingInterval, takeReading);
    });
}

function flashLed() {
    // Turn the LED on (write a HIGH value)
    led.write(1);

    // Pause for half a second
    imp.sleep(0.5);

    // Turn the LED off
    led.write(0);
}

// Listen to agent for changes to Reading Interval
agent.on("readingInt", function(newInterval) {
    readingInterval = newInterval;
    server.log("Reading Interval updated to " + readingInterval);
});

// Take a reading as soon as the device starts up
takeReading();

