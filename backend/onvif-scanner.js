const soap = require('soap');
const path = require('path');

// Helper function to extract the path part of a URL
function extractPath(url) {
    try {
        // Handle potential errors if URL is malformed or doesn't contain '//'
        const protocolIndex = url.indexOf('//');
        if (protocolIndex === -1) return url; // Return original if no protocol found
        const pathIndex = url.indexOf('/', protocolIndex + 2);
        return pathIndex === -1 ? '/' : url.substring(pathIndex);
    } catch (e) {
        console.error(`Error extracting path from URL "${url}":`, e);
        return url; // Return original URL on error
    }
}

// Main function to scan an ONVIF device for profiles/streams
async function scanOnvifDevice(hostname, port, username, password) {
    const wsdlPath = path.join(__dirname, '../wsdl/media_service.wsdl'); // Correct path relative to backend/
    const deviceServiceUrl = `http://${hostname}:${port || 80}/onvif/device_service`; // Use port or default 80

    const options = {
        forceSoap12Headers: true,
        // Add timeout options if needed
        // request: require('request').defaults({'timeout': 5000})
    };

    const securityOptions = {
        hasNonce: true,
        passwordType: 'PasswordDigest'
    };

    let client;
    try {
        client = await soap.createClientAsync(wsdlPath, options);
        client.setEndpoint(deviceServiceUrl);
        if (username && password) {
            client.setSecurity(new soap.WSSecurity(username, password, securityOptions));
        }
    } catch (err) {
        console.error(`Failed to create SOAP client for ${deviceServiceUrl}:`, err);
        throw new Error(`Failed to connect to ONVIF device: ${err.message}`);
    }

    let profilesResponse;
    try {
        profilesResponse = await client.GetProfilesAsync({});
        if (!profilesResponse || !profilesResponse[0] || !profilesResponse[0].Profiles) {
             throw new Error('Invalid response format when fetching profiles.');
        }
    } catch (err) {
        console.error(`Error calling GetProfilesAsync on ${deviceServiceUrl}:`, err);
         if (err.root && err.root.Envelope && err.root.Envelope.Body && err.root.Envelope.Body.Fault) {
            const fault = err.root.Envelope.Body.Fault;
            const reason = fault.Reason?.Text?.$value || JSON.stringify(fault.Reason?.Text) || 'Unknown reason';
            const subcode = fault.Code?.Subcode?.Value?.$value || 'No subcode';
            throw new Error(`ONVIF Error getting profiles: ${reason} (Subcode: ${subcode})`);
        }
        throw new Error(`Failed to get profiles from ONVIF device: ${err.message}`);
    }


    const cameras = {}; // Group profiles by video source token

    for (const profile of profilesResponse[0].Profiles) {
        if (!profile || !profile.VideoSourceConfiguration || !profile.VideoSourceConfiguration.SourceToken || !profile.attributes || !profile.attributes.token) {
            console.warn('Skipping profile due to missing required fields:', profile);
            continue;
        }
        const videoSourceToken = profile.VideoSourceConfiguration.SourceToken;
        const profileToken = profile.attributes.token;

        if (!cameras[videoSourceToken]) {
            cameras[videoSourceToken] = [];
        }

        try {
            // Fetch Snapshot URI
            const snapshotUriResponse = await client.GetSnapshotUriAsync({ ProfileToken: profileToken });
            profile.snapshotUri = snapshotUriResponse?.[0]?.MediaUri?.Uri || null;

            // Fetch Stream URI
            const streamUriResponse = await client.GetStreamUriAsync({
                StreamSetup: { Stream: 'RTP-Unicast', Transport: { Protocol: 'RTSP' } },
                ProfileToken: profileToken
            });
            profile.streamUri = streamUriResponse?.[0]?.MediaUri?.Uri || null;

            cameras[videoSourceToken].push(profile);

        } catch (err) {
            console.error(`Error fetching URIs for profile ${profileToken} (source ${videoSourceToken}):`, err);
            // Decide if we should skip this profile or the whole camera
            // For now, log and continue, the profile might be partially usable or ignored later
        }
    }

    const cameraConfigs = [];

    for (const videoSourceToken in cameras) {
        const profiles = cameras[videoSourceToken];
        if (profiles.length === 0) continue; // Skip if no valid profiles were fetched

        // Sort profiles to try and find best HQ/LQ match (e.g., by resolution, then quality)
        profiles.sort((a, b) => {
            const resA = a.VideoEncoderConfiguration?.Resolution?.Width * a.VideoEncoderConfiguration?.Resolution?.Height || 0;
            const resB = b.VideoEncoderConfiguration?.Resolution?.Width * b.VideoEncoderConfiguration?.Resolution?.Height || 0;
            if (resB !== resA) return resB - resA; // Higher resolution first
            const qualA = a.VideoEncoderConfiguration?.Quality || 0;
            const qualB = b.VideoEncoderConfiguration?.Quality || 0;
            return qualB - qualA; // Higher quality first
        });

        const mainStream = profiles[0];
        const subStream = profiles.length > 1 ? profiles[1] : mainStream; // Use main stream if only one profile

        // Helper to safely access nested properties
        const getProp = (obj, path, defaultValue = null) => path.split('.').reduce((o, p) => (o && o[p] != null) ? o[p] : defaultValue, obj);

        // Extract RTSP port from stream URI, default to 554
        let targetRtspPort = 554;
        try {
            if (mainStream.streamUri) {
                const url = new URL(mainStream.streamUri);
                if (url.port) targetRtspPort = parseInt(url.port, 10);
            }
        } catch (e) { console.warn("Could not parse RTSP port from URI:", mainStream.streamUri); }

        const cameraConfig = {
            original_name: getProp(mainStream, 'VideoSourceConfiguration.Name', `Camera ${videoSourceToken}`),
            profile_token: getProp(mainStream, 'attributes.token'),
            video_source_token: videoSourceToken, // Use the key directly

            hq_rtsp_path: mainStream.streamUri ? extractPath(mainStream.streamUri) : null,
            hq_snapshot_path: mainStream.snapshotUri ? extractPath(mainStream.snapshotUri) : null,
            hq_width: getProp(mainStream, 'VideoEncoderConfiguration.Resolution.Width'),
            hq_height: getProp(mainStream, 'VideoEncoderConfiguration.Resolution.Height'),
            hq_framerate: getProp(mainStream, 'VideoEncoderConfiguration.RateControl.FrameRateLimit'),
            hq_bitrate: getProp(mainStream, 'VideoEncoderConfiguration.RateControl.BitrateLimit'),

            // Use subStream data for LQ, falling back to mainStream if necessary
            lq_rtsp_path: subStream.streamUri ? extractPath(subStream.streamUri) : (mainStream.streamUri ? extractPath(mainStream.streamUri) : null),
            lq_snapshot_path: subStream.snapshotUri ? extractPath(subStream.snapshotUri) : (mainStream.snapshotUri ? extractPath(mainStream.snapshotUri) : null),
            lq_width: getProp(subStream, 'VideoEncoderConfiguration.Resolution.Width', getProp(mainStream, 'VideoEncoderConfiguration.Resolution.Width')),
            lq_height: getProp(subStream, 'VideoEncoderConfiguration.Resolution.Height', getProp(mainStream, 'VideoEncoderConfiguration.Resolution.Height')),
            lq_framerate: getProp(subStream, 'VideoEncoderConfiguration.RateControl.FrameRateLimit', getProp(mainStream, 'VideoEncoderConfiguration.RateControl.FrameRateLimit')),
            lq_bitrate: getProp(subStream, 'VideoEncoderConfiguration.RateControl.BitrateLimit', getProp(mainStream, 'VideoEncoderConfiguration.RateControl.BitrateLimit')),

            target_nvr_rtsp_port: targetRtspPort,
            target_nvr_snapshot_port: port || 80 // NVR HTTP port used for snapshots
        };

        cameraConfigs.push(cameraConfig);
    }

    if (cameraConfigs.length === 0) {
        console.warn(`No usable camera configurations found for ${hostname}:${port}`);
        // Depending on desired behavior, could throw an error here or return empty
    }

    return cameraConfigs;
}

module.exports = { scanOnvifDevice };
