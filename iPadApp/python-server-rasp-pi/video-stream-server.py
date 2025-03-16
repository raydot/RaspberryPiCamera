# Code for the Raspberry Pi RTSP server using GStreamer

#!usr/bin/env python3

import gi
import os
import sys
import signal
import argparse
import logging
import socket

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Check for GStreamer
try:
    gi.require_version('Gst', '1.0')
    gi.require_version('GstRtspServer', '1.0')
    from gi.repository import Gst, GLib, GstRtspServer
except ValueError as e:
    logger.error("GStream 1.0 not found.  Please install with sudo apt-get install libgstreamer1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0plugins-bad gstreamer1.0-plugins-ugly libgstrtspserver-1.0-dev")
    sys.exit(1)

# Initialize GStreamer
Gst.init(None)

class RTSPServer:
    def __init__(self, port=8554, width=640, height=480, framerate=25, mock_mode=False):
        self.port = port
        self.width = width
        self.height = height
        self.framerate = framerate
        self.mock_mode = mock_mode
        self.pipeline = None
        self.loop = None
    
    def build_pipeline(self):
        # Create the pipeline string based on mode
        if self.mock_mode:
            # Test source for systems without a camera
            pipeline_str = (
                f"videotestsrc is-live=true ! video/x-raw,width={self.width},height={self.height},framerate={self.framerate}/1 ! "
                f"videoconvert ! x264enc tune=zerolatency speed-preset=superfast bitrate=500 key-int-max=15 ! "
                f"h264parse ! rtph264pay name=pay0 pt=96 config-interval=1"
            )
        else:
            # Raspberry Pi camera source - using hardware acceleration when possible
            pipeline_str = (
                f"rpicamsrc bitrate=1000000 ! video/x-raw,width={self.width},height={self.height},framerate={self.framerate}/1 ! "
                f"v4l2convert ! v4l2h264enc extra-controls=\"controls,video_bitrate=1000000,video_bitrate_mode=1,h264_profile=1,h264_level=10\" ! "
                f"h264parse ! rtph264pay name=pay0 pt=96 config-interval=1"
            )
            
            # Alternative pipeline using software encoding if hardware encoding fails
            # pipeline_str = (
            #    f"rpicamsrc bitrate=1000000 ! video/x-raw,width={self.width},height={self.height},framerate={self.framerate}/1 ! "
            #    f"videoconvert ! x264enc tune=zerolatency speed-preset=superfast bitrate=500 key-int-max=15 ! "
            #    f"h264parse ! rtph264pay name=pay0 pt=96 config-interval=1"
            # )
        
        logger.info(f"Pipeline: {pipeline_str}")
        return pipeline_str

    def start(self):
        try:
            # Create GStreamer RTSP server
            self.server = GstRtspServer.RTSPServer()
            self.server.set_service(str(self.port))

            # Create RTSP media factory
            factory = GstRtspServer.RTSPMediaFactory()
            factory.set_launch(self.build_pipeline())
            factory.set_shared(True) # share a single pipeline among all clients

            # Add media factory to server
            mount_points = self.server.get_mount_points()
            mount_points.add_factory("/stream", factory)

            # Start the server
            self.server.attach(None)

            # Create and run the main loop
            self.loop = GLib.MainLoop()

            # Print server information
            ip_address = self.get_ip_address()
            logger.info(f"RTSP server started at: rtsp://{ip_address}:{self.port}/stream")
            logger.info("Press Ctrl+C to stop the server")

            # Run the main loop
            self.loop.run()

        except Exception as e:
            logger.error(f"Failed to start RTSP server: {e}")
            self.stop()

        def stop(self):
            if self.loop and self.loop.is_running():
                self.loop.quit()
                logger.info("Server stopped")
            
        def get_ip_address(self):
            """Get the local UP address of the machine"""
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                # doesn't even have to be reachable
                s.connect(("10.255.255.255", 1))
                IP = s.getsockname()[0]
            except Exception:
                IP = "127.0.0.1"
            finally:
                s.close()
            return IP

    def signal_handler(sig, frame):
        logger.info("Received interrupt signal, shutting down...")
        if server:
            server.stop()
        sys.exit(0)

    if __name__ == "__main__":
        parser = argparse.ArgumentParser(description='RTSP camera server for Raspberry Pi')
        parser.add_argument('--port', type=int, default=8554, help='RTSP server port')
        parser.add_argument('--width', type=int, default=640, help='Video width')
        parser.add_argument('--height', type=int, default=480, help='Video height')
        parser.add_argument('--framerate', type=int, default=25, help='Video framerate')
        parser.add_argument('--mock', action='store_true', help='Use test video source instead of camera')
        args = parser.parse_args()

        # Set up signal handling for clean shutdown
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

        # Create and start the RTSP server
        server = RTSPServer(port=args.port, width=args.width, height=args.height, framerate=args.framerate, mock_mode=args.mock)
        server.start()