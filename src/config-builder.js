const soap = require('soap');
const uuid = require('node-uuid');

function extractPath(url) {
    return url.substr(url.indexOf('/', url.indexOf('//') + 2));
}

async function createConfig(hostname, port, username, password) {
    let options = {
        forceSoap12Headers: true
    };

    let securityOptions = {
        hasNonce: true,
        passwordType: 'PasswordDigest'
    };
    
    let client = await soap.createClientAsync('./wsdl/media_service.wsdl', options);
    client.setEndpoint(`http://${hostname}/onvif/device_service`);
    client.setSecurity(new soap.WSSecurity(username, password, securityOptions));

    let hostport = 80;
    if (hostname.indexOf(':') > -1) {
        hostport = parseInt(hostname.substr(hostname.indexOf(':') + 1));
        hostname = hostname.substr(0, hostname.indexOf(':'));
    }

    let cameras = {};

    try {
        let profiles = await client.GetProfilesAsync({});
        for (let profile of profiles[0].Profiles) {
            let videoSource = profile.VideoSourceConfiguration.SourceToken;

            if (!cameras[videoSource])
                cameras[videoSource] = [];

            let snapshotUri = await client.GetSnapshotUriAsync({
                ProfileToken: profile.attributes.token
            });

            let streamUri = await client.GetStreamUriAsync({
                StreamSetup: {
                    Stream: 'RTP-Unicast',
                    Transport: {
                        Protocol: 'RTSP'
                    }
                },
                ProfileToken: profile.attributes.token
            });

            profile.streamUri = streamUri[0].MediaUri.Uri;
            profile.snapshotUri = snapshotUri[0].MediaUri.Uri;
            cameras[videoSource].push(profile);
        }
    } catch (err) {
        if (err.root && err.root.Envelope && err.root.Envelope.Body && err.root.Envelope.Body.Fault && err.root.Envelope.Body.Fault.Reason && err.root.Envelope.Body.Fault.Reason.Text)
            throw `Error: ${err.root.Envelope.Body.Fault.Reason.Text['$value']}`;
        throw `Error: ${err.message}`;
    }

    let cameraConfigs = [];

    for (let camera in cameras) {
        let mainStream = cameras[camera][0];
        let subStream = cameras[camera][cameras[camera].length > 1 ? 1 : 0];

        let swapStreams = false;
        if (subStream.VideoEncoderConfiguration.Quality > mainStream.VideoEncoderConfiguration.Quality)
            swapStreams = true;
        else if (subStream.VideoEncoderConfiguration.Quality == mainStream.VideoEncoderConfiguration.Quality)
            if (subStream.VideoEncoderConfiguration.Resolution.Width > mainStream.VideoEncoderConfiguration.Resolution.Width)
                swapStreams = true;

        if (swapStreams) {
            let tempStream = subStream;
            subStream = mainStream;
            mainStream = tempStream;
        }

        let cameraConfig = {
            original_name: mainStream.VideoSourceConfiguration.Name,
            profile_token: mainStream.attributes.token,
            video_source_token: mainStream.VideoSourceConfiguration.SourceToken,
            hq_rtsp_path: extractPath(mainStream.streamUri),
            hq_snapshot_path: extractPath(mainStream.snapshotUri),
            hq_width: mainStream.VideoEncoderConfiguration.Resolution.Width,
            hq_height: mainStream.VideoEncoderConfiguration.Resolution.Height,
            hq_framerate: mainStream.VideoEncoderConfiguration.RateControl.FrameRateLimit,
            hq_bitrate: mainStream.VideoEncoderConfiguration.RateControl.BitrateLimit,
            lq_rtsp_path: extractPath(subStream.streamUri),
            lq_snapshot_path: extractPath(subStream.snapshotUri),
            lq_width: subStream.VideoEncoderConfiguration.Resolution.Width,
            lq_height: subStream.VideoEncoderConfiguration.Resolution.Height,
            lq_framerate: subStream.VideoEncoderConfiguration.RateControl.FrameRateLimit,
            lq_bitrate: subStream.VideoEncoderConfiguration.RateControl.BitrateLimit,
            target_nvr_rtsp_port: 554, // Default RTSP port
            target_nvr_snapshot_port: port // NVR HTTP port
        };

        cameraConfigs.push(cameraConfig);
    }

    return cameraConfigs;
}

exports.createConfig = async function(hostname, port, username, password) {
    try {
        return await createConfig(hostname, port, username, password);
    } catch (err) {
        console.error(err);
        throw err; // Re-throw the error to be handled by the caller
    }
}
