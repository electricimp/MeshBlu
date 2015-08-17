class Meshblu {

    static version = [1, 0, 0];

    static NO_CREDENTIALS_ERR = "Meshblu Credentials Missing";
    static CREDENTIALS_ERR = "Device already has Meshblu Credentials";
    static RESP_ERR = "Error communicating with Meshblu";

    _baseUrl = "https://meshblu.octoblu.com"
    _uuid = null;
    _token = null;
    _headers = null;
    _properties = null;
    _streamingRequest = null;

    constructor (properties = {}) {
        // Set the initial header
        _headers = {"Content-Type" : "application/json"};

        // Add all the properties passed in
        _updateProperties(properties);
    }

    // Register a device with Meshblu (only if no credentials passed in)
    function registerDevice(cb) {
        // Ensure we're not registered
        if(_deviceRegistered() ) {
            imp.wakeup(0, function() { cb(Meshblu.CREDENTIALS_ERR, null, null); });
            return;
        }

        local url = format("%s/devices", _baseUrl);
        local request = http.post(url, _headers, http.jsonencode(_properties));
        local error = "Could not register device"

        request.sendasync(function(resp) {
            local data = {};
            local err = null;

            // decode data
            try {
                data = http.jsondecode(resp.body);
            } catch (ex) {
                imp.wakeup(0, function() { cb(ex, resp, null); });
                return
            }

            // check status code
            if (resp.statuscode != 201) {
                err = (format("Could not register device (%s)", resp.statuscode.tostring()));
                imp.wakeup(0, function() { cb(err, resp, data); });
                return
            }

            // check that credentials were returned
            if("uuid" in data && "token" in data) {
                _updateLocalCredentials(data.uuid, data.token);
            } else {
                err = "Credentials not sent";
            }

            // your callback should to store the tokens for future access to your device
            imp.wakeup(0, function() { cb(err, resp, data); });
        }.bindenv(this));
    }

    // Gets this device info
    function getDeviceInfo(uuid, cb) {
        // Ensure we're registered
        if(!_deviceRegistered()) {
            imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        local url = format("%s/devices/%s", _baseUrl, uuid);
        local request = http.get(url, _headers);
        _sendRequest(request, cb);
    }

    // Update properties of a specific device
    function updateDevice(newProps, cb = null) {
        // Ensure we're registered
        if (!_deviceRegistered()) {
            if (cb) imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        _updateProperties(newProps);
        local url = format("%s/devices/%s", _baseUrl, _uuid);
        local request = http.put(url, _headers, http.jsonencode(_properties));
        _sendRequest(request, cb);
    }

    // Delete device from meshblu network
    function deleteDevice(cb = null) {
        // Ensure we're registered
        if( !_deviceRegistered() ) {
            if (cb) imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        local url = format("%s/devices/%s", _baseUrl, _uuid);
        local request = http.httpdelete(url, _headers);

        request.sendasync(function(resp) {
            local data = {};
            local err = null;

            // decode data
            try {
                data = http.jsondecode(resp.body);
            } catch (ex) {
                if (cb) imp.wakeup(0, function() { cb(ex, resp, null); });
                return
            }

            // check status code
            if (resp.statuscode != 200) {
                err = (format("Could not delete device (%s)", resp.statuscode.tostring()));
                if(cb) imp.wakeup(0, function() { cb(err, resp, data); });
                return
            }

            _removeLocalCredentials();
            if(cb) imp.wakeup(0, function() { cb(err, resp, data); });
        }.bindenv(this));

    }

    function getLocalDevices(cb) {
        // Ensure we're registered
        if( !_deviceRegistered() ) {
            imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        local url = format("%s/localdevices", _baseUrl);
        local request = http.get(url, _headers);
        _sendRequest(request, cb);
    }

    function online(cb = null) {
        updateDevice({"online" : true}, cb);
    }

    function offline(cb = null) {
        updateDevice({"online" : false}, cb);
    }

    // data should be in key:value pairs
    function storeData(devData, cb = null) {
        // Ensure we're registered
        if( !_deviceRegistered() ) {
            if(cb) imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }
        local url = format("%s/data/%s", _baseUrl, _uuid);
        local request = http.post(url, _headers, http.jsonencode(devData));

        request.sendasync(function(resp) {
            local err = null;

            if (resp.statuscode != 201) {
                err = format("Could not store data (%s)", resp.statuscode.tostring());
                if(cb) imp.wakeup(0, function() { cb(err, resp, resp.body); });
            } else {
                if(cb) imp.wakeup(0, function() { cb(null, resp, resp.body); });
            }
        }.bindenv(this));
    }

    // TODO: add query params
    function getData(uuid, cb, stream = false) {
        // Ensure we're registered
        if( !_deviceRegistered() ) {
            imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        local url = format("%s/data/%s", _baseUrl, uuid);
        if(stream) { url = format("%s/data/%s?stream=true", _baseUrl, uuid); }
        local request = http.get(url, _headers);
        _sendRequest(request, cb);
    }

    // must be subscribed to get data stream
    function getStreamingData(uuid) {
        getData(uuid, null, true);
    }

    // Send a message to a specific device, array of devices, or all devices subscribing to a UUID on the Meshblu platform
    function sendMessage(device, message, cb = null) {
        // Ensure we're registered
        if( !_deviceRegistered() ) {
            if(cb) imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        local d = { "devices" : device, "payload" : message };
        local url = format("%s/messages", _baseUrl);
        local request = http.post(url, _headers, http.jsonencode(d));
        _sendRequest(request, cb);
    }

    // subscribe to device
    function subscribe(uuid, cb, filter=null) {
        // Ensure we're registered
        if( !_deviceRegistered() ) {
            if(cb) imp.wakeup(0, function() { cb(Meshblu.NO_CREDENTIALS_ERR, null, null); });
            return;
        }

        local url = format("%s/subscribe/%s", _baseUrl, uuid);
        if(filter) { url = format("%s/subscribe/%s%s", _baseUrl, uuid, filter); }

        _openStream(url, cb);
    }

    // types (broadcast, received, sent, or [broadcast, received])
    function subscribeWithTypeFilter(uuid, types, cb) {
        if(typeof types == "array") {
            local urlEncodedFilter = "?";
            foreach(index, item in types) {
                if(index == 0) {
                    urlEncodedFilter = format("%stypes=%s", urlEncodedFilter, item);
                }else{
                    urlEncodedFilter = format("%s&types=%s", urlEncodedFilter, item);
                }
            }
            subscribe(uuid, cb, urlEncodedFilter);
        } else {
            subscribe(uuid, cb, format("/%s", types));
        }
    }

    // Get status of meshblu network
    function getNetworkStatus(cb) {
        local url = format("%s/status", _baseUrl);
        local request = http.get(url, {});
        _sendRequest(request, cb);
    }

    // Sets the internally stored credentials
    function setDeviceCredentials(uuid, token) {
        _updateLocalCredentials(uuid, token);
    }

    // Gets the internally stored credentials
    function getDeviceCredentials() {
        if (_deviceRegistered()) {
            return { "uuid": _uuid, "token": _token };
        } else {
            return null;
        }
    }

    //--------------- PRIVATE FUNCTIONS - DO NOT CALL ---------------//

    function _deviceRegistered() {
        return (_uuid != null && _token != null);
    }

    function _updateProperties(newProps) {
        if("uuid" in newProps) {
            _updateLocalCredentials(uuid.newProps, null);
        }
        if("token" in newProps) {
            _updateLocalCredentials(null, token.newProps);
        }
        foreach (prop, val in newProps) {
            _properties[prop] <- val;
        }

        // Delete the uuid & token credentials from the _properties table
        _deleteCredentialsFromPropperties();
    }

    function _deleteCredentialsFromPropperties() {
        _properties.rawdelete("uuid");
        _properties.rawdelete("token");
    }

    function _updateLocalCredentials(uuid, token) {
        if(uuid) {
            _uuid = uuid;
            _headers.meshblu_auth_uuid <- _uuid;
        }
        if(token) {
            _token = token;
            _headers.meshblu_auth_token <- _token;
        }
    }

    function _removeLocalCredentials() {
        // remove locally stored uuid & token
        _uuid = null;
        _token = null;
        _headers = { "Content-Type" : "application/json" };
    }

    function _sendRequest(request, cb, statusCode=200) {
        request.sendasync(function(resp) {
            local data = {};
            local err = null;

            try {
                data = http.jsondecode(resp.body);
            } catch (ex) {
                if(cb) imp.wakeup(0, function() { cb(ex, resp, null); });
                return
            }

            if (resp.statuscode != statusCode) {
                local err = format("%s (%s)", RESP_ERR, resp.statuscode.tostring());
                if(cb) imp.wakeup(0, function() { cb(err, resp, data); });
                return
            }

            if(cb) imp.wakeup(0, function() { cb(err, resp, data); });
        }.bindenv(this));
    }

    function _openStream(url, cb, reconnect=true, streamingRetryTimeout = 10.0) {
        if(_streamingRequest != null) {
            _streamingRequest.cancel();
            _streamingRequest = null;
        }
        _streamingRequest = http.get(url, _headers);

        _streamingRequest.sendasync(function(resp) {
            if (reconnect) { _openStream(url, cb, true); }
        }.bindenv(this), function(data) {
            local decodedData = null;
            local err = null;

            try {
                decodedData = http.jsondecode(data);
            } catch (ex) {
                // if stream listening to multiple subscribe types
                // data includes multiple responses separated by a new line
                try {
                    decodedData = split(data, "\n\r");
                    foreach(index, response in decodedData) {
                        decodedData[index] = http.jsondecode(response);
                    }
                } catch (ex) {
                    err = ex;
                }
            }

            if(cb) imp.wakeup(0, function() { cb(err, data, decodedData); });
        }.bindenv(this));
    }
}
