## Octoblu Setup
Login into [octoblu.com](https://app.octoblu.com/login?callbackUrl=%2Fdesign). Using the menu icon on the left navigate to **Discover**. Find the **Electric Imp Environmental Sensor Tail** blueprint and import it.

###Connect Device to Account
Navigate to **Things**. At the top of the Things page, click **claim your device manually**. Enter a name for your device, the **uuid** and **token** from the IDE logs.

Next you need to configure your device's permissions. Click on **permissions** and look for your device's uuid.  Check all the checkboxes for your device.

###Configure Flow
The preconfigured blueprint has a number of placeholders that you will need to update.  There are comments in the flow to help guide you.

####Required
######Connect Imp
Navigate to **Design**.  In the flow click on the **Imp Environmental Sensor Tail** icon.  On the right you should now be able to see the Imp's **thing inspector**.  To connect your imp to the flow:

* click the **setup** button
* click **connect a generic device**
* change the dropdown to **claim an existing thing**
  * enter a **name**, the **uuid** and **token** from the IDE logs
* click **connect generic device**

Navigate back to **Design**.  Your device should now be connected. When you click on the **Imp Environmental Sensor Tail icon** the Imp's **thing inspector** should have your device name listed under **Available Things**.  If the inspector is still showing the setup button, refresh the webpage.

######Enter SMS number
The SMS is preconfigured with a dummy phone number.  To receive text notifications you will need to update the phone number for both of the **send SMS** icons.

* click each **send SMS** icon
* in the inspector, enter a phone number in **destination number(s)**

####Optional

######Set Reading Interval
To adjust the time the Imp waits between readings you can adjust the message sent by the **Trigger**.  The trigger will send a message only when the flow is started and the triangle next to the button is pressed. To adjust the time:

* click **Trigger** icon
* in the inspector, adjust the **reading interval object** to the desired time in seconds

######Set Temperature and Humidity Thresholds

To adjust the temperature or humidity threshholds:

* click the **comparison** icon(s)
* in the inspector, change the **right** value.

####Start Flow
When you are done adjusting the flow, click the **start** icon in the top right of the window.  This connects the flow to the network.  If you have changed the reading interval, click the triangle next to the trigger button to send the new reading interval to your Imp.

