class Meshblu {

    static version = [1, 0, 0];

    static NO_CREDENTIALS_ERR = "ERROR: Meshblu Credentials Missing";
    static CREDENTIALS_ERR = "ERROR: Device already has MeshBlu Credentials";
    static RESP_ERR = "Error communicating with MeshBlu";

    _baseUrl = "https://meshblu.octoblu.com"
    _token = null;
    _uuid = null;
    _headers = null;
    _properties = null;
    _streamingRequest = null;

    constructor (properties={}) {
        _properties = properties;
        _headers = {"Content-Type" : "application/json"};

        if("token" in properties) {
            _token = properties.token;
            _headers.meshblu_auth_token <- _token;
        }
        if("uuid" in properties) {
            _uuid = properties.uuid;
            _headers.meshblu_auth_uuid <- _uuid;
        }
    }

    // Register a device with Meshblu (only if no credentials passed in)
    function registerDevice(cb) {
        if( _deviceRegistered() ) {
            cb(CREDENTIALS_ERR, null, null);
        } else {
            local url = format("%s/devices", _baseUrl);
            local request = http.post(url, _headers, http.jsonencode(_properties));
            local error = "ERROR: Could not register device"

            request.sendasync(function(resp) {
                local data = {};
                local err = null;

                // decode data
                try {
                    data = http.jsondecode(resp.body);
                } catch (ex) {
                    cb(ex, resp, null);
                    return
                }

                // check status code
                if (resp.statuscode != 201) {
                    err = (format("ERROR: Could not register device (%s)", resp.statuscode.tostring()));
                    cb(err, resp, data);
                    return
                }

                // check that credentials were returned
                if("uuid" in data && "token" in data) {
                    _updateLocalCredentials(data.uuid, data.token);
                } else {
                    err = "ERROR: Credentials not sent";
                }

                // your callback should to store the tokens for future access to your device
                cb(err, resp, data);
            }.bindenv(this));
        }
    }

    // Gets this device info
    function getDeviceInfo(uuid, cb) {
        if( !_deviceRegistered() ) {
            cb(NO_CREDENTIALS_ERR, null, null);
        } else {
            local url = format("%s/devices/%s", _baseUrl, uuid);
            local request = http.get(url, _headers);
            _sendRequest(request, cb);
        }
    }

    // Update properties of a specific device
    function updateDevice(newProps, cb=null) {
        if( !_deviceRegistered() ) {
            if(cb) { cb(NO_CREDENTIALS_ERR, null, null); }
        } else {
            _updateProperties(newProps);
            local url = format("%s/devices/%s", _baseUrl, _properties.uuid);
            local request = http.put(url, _headers, http.jsonencode(_properties));
            _sendRequest(request, cb);
        }
    }

    // Delete device from meshblu network
    function deleteDevice(cb=null) {
        if( !_deviceRegistered() ) {
            if(cb) { cb(NO_CREDENTIALS_ERR, null, null); }
        } else {
            local url = format("%s/devices/%s", _baseUrl, _properties.uuid);
            local request = http.httpdelete(url, _headers);

            request.sendasync(function(resp) {
                local data = {};
                local err = null;

                // decode data
                try {
                    data = http.jsondecode(resp.body);
                } catch (ex) {
                    if(cb) { cb(ex, resp, null); }
                    return
                }

                // check status code
                if (resp.statuscode != 200) {
                    err = (format("ERROR: Could not delete device (%s)", resp.statuscode.tostring()));
                    if(cb) { cb(err, resp, data); }
                    return
                }

                _removeLocalCredentials();
                if(cb) { cb(err, resp, data); }
            }.bindenv(this));
        }
    }

    function getLocalDevices(cb) {
         if( !_deviceRegistered() ) {
            cb(NO_CREDENTIALS_ERR, null, null);
        } else {
            local url = format("%s/localdevices", _baseUrl);
            local request = http.get(url, _headers);
            _sendRequest(request, cb);
        }
    }

    function online(cb=null) {
        updateDevice({"online" : true}, cb);
    }

    function offline(cb=null) {
        updateDevice({"online" : false}, cb);
    }

    // data should be in key:value pairs
    function storeData(devData, cb=null) {
        if( !_deviceRegistered() ) {
            if(cb) { (NO_CREDENTIALS_ERR, null, null); }
        } else {
            local url = format("%s/data/%s", _baseUrl, _properties.uuid);
            local request = http.post(url, _headers, http.jsonencode(devData));

            request.sendasync(function(resp) {
                local err = null;

                if (resp.statuscode != 201) {
                    err = format("ERROR: Could not store data (%s)", resp.statuscode.tostring());
                    if(cb) { cb(err, resp, resp.body); }
                } else {
                    if(cb) { cb(null, resp, resp.body); }
                }
            }.bindenv(this));
        }
    }

    // TODO: add query params
    function getData(uuid, cb, stream=false) {
        if( !_deviceRegistered() ) {
            if(cb) { cb(NO_CREDENTIALS_ERR, null, null); }
        } else {
            local url = format("%s/data/%s", _baseUrl, uuid);
            if(stream) { url = format("%s/data/%s?stream=true", _baseUrl, uuid); }
            local request = http.get(url, _headers);
            _sendRequest(request, cb);
        }
    }

    // must be subscribed to get data stream
    function getStreamingData(uuid) {
        getData(uuid, null, true);
    }

    // Send a message to a specific device, array of devices, or all devices subscribing to a UUID on the Meshblu platform
    function sendMessage(device, message, cb=null) {
        if( !_deviceRegistered() ) {
            if(cb) { cb(NO_CREDENTIALS_ERR, null, null); }
        } else {
            local d = { "devices" : device, "payload" : message };
            local url = format("%s/messages", _baseUrl);
            local request = http.post(url, _headers, http.jsonencode(d));
            _sendRequest(request, cb);
        }
    }

    // subscribe to device
    function subscribe(uuid, cb, filter=null) {
        if( !_deviceRegistered() ) {
            cb(NO_CREDENTIALS_ERR, null, null);
        } else {
            local url = format("%s/subscribe/%s", _baseUrl, uuid);
            if(filter) { url = format("%s/subscribe/%s%s", _baseUrl, uuid, filter); }

            _openStream(url, cb);
        }
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

    /////////////////// PRIVATE FUNCTIONS - DO NOT CALL ///////////////

    function _updateProperties(newProps) {
        foreach (prop, val in newProps) {
            _properties[prop] = val;
        }
    }

    function _deviceRegistered() {
        return ("uuid" in _properties && "token" in _properties);
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
        _properties.rawDelete("uuid");
        _properties.rawDelete("token");
        _headers = {"Content-Type" : "application/json"};
    }

    function _sendRequest(request, cb, statusCode=200) {
        request.sendasync(function(resp) {
            local data = {};
            local err = null;

            try {
                data = http.jsondecode(resp.body);
            } catch (ex) {
                if(cb) { cb(ex, resp, null); }
                return
            }

            if (resp.statuscode != statusCode) {
                local err = format("%s (%s)", RESP_ERR, resp.statuscode.tostring());
                if(cb) { cb(err, resp, data); }
                return
            }

            if(cb) { cb(err, resp, data); }
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

            cb(err, data, decodedData);
        }.bindenv(this));
    }

}
