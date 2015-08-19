# Octoblu Example

This example uses the Meshblu library to boradcast temperature and humidity data from an Imp to Octoblu's m2m instant messaging IoT Platform. Using Octoblu's web app we send text messages if the temperatrue or humidity is outside of a set range.

## Hardware
All the hardware needed for this project can be found on Amazon in [Electric Imp's WiFi Environmental Sensor & Led kit](http://www.amazon.com/WiFi-Environmental-Sensor-LED-kit/dp/B00ZQ4D1TM/ref=sr_1_1?ie=UTF8&qid=1439943458&sr=8-1&keywords=electric+imp). For this project we will be using:

* Imp001
* April Breakout Board
* Environmental Sensor tail
* USB power cable

## Imp Setup
Blink up your Imp and copy and paste the example agent and device code into your IDE.  When you hit build and run your Meshblue device credentials will be printed in the logs.  You will need the uuid and token to set up your Imp in Octoblu's web app.

## Octoblu Setup
Login into [octoblu.com](https://app.octoblu.com/login?callbackUrl=%2Fdesign). Using the menu icon on the left navigate to **Discover**. Find the **Electric Imp Environmental Sensor Tail** blueprint and import it.

####Connect Device to Account
Using the menu icon on the left navigate to **Things**. At the top of the **Things** page click **claim your device manually**. Enter a name for your device & the **uuid** and **token** from your ide logs.

Configure your devices permissions by clicking on the permissions tab and checking all the checkboxes for the device with your uuid.

####Configure Flow
The preconfigured blueprint has a number of placeholders that you will need to update.  There are comments to help guide you.

#####Required Configuration
######Connect Imp
Navigate to **Design**.  In the flow click on the **Imp Environmental Sensor Tail icon**.  On the right you should now be able to see the Imp's **thing inspector**.  To connect your imp to the flow:

* click the **setup** button
* click **connect a generic device**
* change the dropdown to **claim an existing thing**
  * enter a **name** and the **uuid** and **token** from your ide logs
* click **connect generic device**

Using the sidebar on the left navigate back to **Design**.  Your device should now be connected. When you click on the **Imp Environmental Sensor Tail icon** the Imp's **thing inspector** should have your device name listed under **Available Things**.  If the inspector is still showing the setup button, refresh the webpage.

######Enter SMS number
The SMS is preconfigured with a dummy phone number.  To receive text notifications you will need to update the phone number for both **send SMS**.

* click the **send SMS icon(s)**
* in the inspector, enter your phone number in the **destination number(s)**

#####Optional Configuration

######Set Reading Interval
To adjust the time the Imp waits between readings you can adjust the message sent by the **Trigger**.  The trigger will send a message only when the flow is started and the triangle next to the button is pressed.

* click **Trigger** icon
* in the inspector, adjust the **reading interval object** to the desired time in seconds

######Set Temperature and Humidity Thresholds

To adjust the temperature or humidity threshholds change the **right** values in the comparison inspectors.

####Start Flow
When you are done adjusting settings in the flow, click the **start** icon in the top right of the window.  This will start your flow.  If you have changed the reading interval click the triangle next to the trigger button to send the new reading interval to your imp.
