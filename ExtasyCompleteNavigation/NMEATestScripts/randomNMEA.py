#!/usr/bin/env python3

import math
import random
import socket
import time

# Configuration settings
CONFIG = {
    "start_latitude": 43.18447,
    "start_longitude": 27.99403,
    "true_wind_direction": 360,  # Static or adjustable True Wind Direction (TWD)
    "initial_heading": 90,     # Heading of the boat (used for TWA)
    "cog_heading": 73,         # Separate COG (Course Over Ground)
    "magnetic_heading": 73,    # Separate magnetic heading
    "heading_limits": {"upper": 73, "lower": 73},
    "log_speed_knots": 8.0,     # Speed through water (log)
    "sog_speed_knots": 7.0,     # Speed over ground (SOG)
    "wind_speed_knots": 10.0,   # Wind speed
    "ips": ["127.0.0.1"],
    "udp_port": 4950,
    "update_interval": 1.0,     # Time in seconds
}

# Utility functions
def calculate_checksum(sentence):
    checksum = 0
    for char in sentence:
        checksum ^= ord(char)
    return f"{checksum:02X}"

def normalize_angle(angle):
    """Normalize any angle to the range [0, 360)."""
    return angle % 360

def normalize_angle_180(angle):
    """Normalize any angle to the range [-180, 180]."""
    angle = angle % 360
    if angle > 180:
        angle -= 360
    return angle

def calculate_twa(true_wind_direction, current_heading):
    """
    Calculate True Wind Angle (TWA) based on true wind direction and current heading.
    TWA is normalized to [-180, 180].
    """
    # Normalize inputs
    true_wind_direction = normalize_angle(true_wind_direction)
    current_heading = normalize_angle(current_heading)

    # Calculate the difference and normalize to [-180, 180]
    return true_wind_direction - current_heading

# Sentence generators
class NMEASentenceGenerator:
    def __init__(self, config):
        self.latitude = config["start_latitude"]
        self.longitude = config["start_longitude"]
        self.true_wind_direction = config["true_wind_direction"]
        self.heading = config["initial_heading"]  # Boat heading (used for TWA)
        self.cog_heading = config["cog_heading"]  # Separate COG heading
        self.magnetic_heading = config["magnetic_heading"]
        self.heading_limits = config["heading_limits"]
        self.log_speed_knots = config["log_speed_knots"]
        self.sog_speed_knots = config["sog_speed_knots"]
        self.wind_speed_knots = config["wind_speed_knots"]

    def update_heading(self):
        # Update boat heading independently
        #self.heading += random.uniform(-1, 1)
        self.heading = normalize_angle(self.heading)

    def update_cog_and_magnetic_heading(self):
        # Add some variability to COG and magnetic heading
        #self.cog_heading += random.uniform(-2, 2)
        #self.magnetic_heading += random.uniform(-1, 1)
        self.cog_heading = normalize_angle(self.cog_heading)
        self.magnetic_heading = normalize_angle(self.magnetic_heading)

    def update_speeds(self):
        # Add variability to speeds
        self.log_speed_knots += random.uniform(-0.5, 0.5)
        self.sog_speed_knots += random.uniform(-0.5, 0.5)
        self.wind_speed_knots += random.uniform(-0.05, 0.05)

        # Clamp speeds to realistic ranges
        self.log_speed_knots = max(4.0, min(12.0, self.log_speed_knots))  # Log speed between 4 and 12 knots
        self.sog_speed_knots = max(3.0, min(10.0, self.sog_speed_knots))  # SOG between 3 and 10 knots
        self.wind_speed_knots = max(5.0, min(20.0, self.wind_speed_knots))  # Wind speed between 5 and 20 knots

    @staticmethod
    def generate_depth_sentence():
        depth = random.uniform(35.0, 50.0)
        nmea_base = f"IIDPT,{depth:.1f},,"
        checksum = calculate_checksum(nmea_base)
        return f"${nmea_base}*{checksum}"

    def generate_speed_sentence(self):
        nmea_base = f"IIVHW,{self.heading:.0f},T,{self.magnetic_heading:.0f},M,{self.log_speed_knots:.2f},N"
        checksum = calculate_checksum(nmea_base)
        return f"${nmea_base}*{checksum}"

    def generate_heading_sentence(self):
        nmea_base = f"IIHDG,{self.magnetic_heading:.1f},,,0.0,E"
        checksum = calculate_checksum(nmea_base)
        return f"${nmea_base}*{checksum}"

    @staticmethod
    def generate_temperature_sentence():
        temperature = random.uniform(30, 40)
        nmea_base = f"IIMTW,{temperature:.1f},C"
        checksum = calculate_checksum(nmea_base)
        return f"${nmea_base}*{checksum}"

    def generate_true_wind_sentence(self):
        twa = calculate_twa(self.true_wind_direction, self.heading)  # TWA based on boat heading
        wind_speed = self.wind_speed_knots  # Use the separate wind speed value
        nmea_base = f"IIMWV,{abs(twa):.0f},T,{wind_speed:.1f},N,A"
        checksum = calculate_checksum(nmea_base)
        return f"${nmea_base}*{checksum}"

    def generate_gps_sentence(self):
        distance_nm = self.sog_speed_knots * (1.5 / 3600)  # Distance traveled in nautical miles
        heading_rad = math.radians(self.cog_heading)  # Use COG for GPS position update

        delta_latitude = distance_nm * math.cos(heading_rad) / 60.0
        delta_longitude = distance_nm * math.sin(heading_rad) / (60.0 * math.cos(math.radians(self.latitude)))

        self.latitude += delta_latitude
        self.longitude += delta_longitude

        lat_degrees = int(abs(self.latitude))
        lat_minutes = (abs(self.latitude) - lat_degrees) * 60
        latitude = f"{lat_degrees:02}{lat_minutes:07.4f}"
        lat_dir = "N" if self.latitude >= 0 else "S"

        lon_degrees = int(abs(self.longitude))
        lon_minutes = (abs(self.longitude) - lon_degrees) * 60
        longitude = f"{lon_degrees:03}{lon_minutes:07.4f}"
        lon_dir = "E" if self.longitude >= 0 else "W"

        nmea_base = f"GPRMC,080820.000,A,{latitude},{lat_dir},{longitude},{lon_dir},{self.sog_speed_knots:.2f},{self.cog_heading:.1f},181223,,,A"
        checksum = calculate_checksum(nmea_base)
        return f"${nmea_base}*{checksum}"

# UDP sender
class NMEASender:
    def __init__(self, ips, port):
        self.ips = ips
        self.port = port

    def send(self, sentence):
        for ip in self.ips:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
                sock.sendto(sentence.encode(), (ip, self.port))
            print(f"Sent to {ip}: {sentence}")

# Main function
def main():
    generator = NMEASentenceGenerator(CONFIG)
    sender = NMEASender(CONFIG["ips"], CONFIG["udp_port"])

    while True:
        generator.update_heading()
        generator.update_cog_and_magnetic_heading()
        generator.update_speeds()

        sentences = [
            generator.generate_depth_sentence(),
            generator.generate_speed_sentence(),
            generator.generate_heading_sentence(),
            generator.generate_temperature_sentence(),
            generator.generate_true_wind_sentence(),
            generator.generate_gps_sentence(),
        ]

        for sentence in sentences:
            sender.send(sentence)

        time.sleep(CONFIG["update_interval"])

if __name__ == "__main__":
    main()
