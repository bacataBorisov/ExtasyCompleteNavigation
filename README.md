# Extasy Complete Navigation

## Project description

This app was designed for a particular sailing boat but can be further developed to fit the needs of any other boat or vessel that works with the NMEA standard. It uses a Raspberry Pi connected to the B&G serial bus, receiving NMEA signals from various sensors (speed, wind, magnetic compass, depth, GPS). NMEA strings are sent over Wi-Fi via socket communication on port 4950, and the data is displayed in a user-friendly way on iOS devices (iPhone, iPad). 

### Note: The app requires an iOS device with iOS 17 or later.

Key Features:

- Displays real-time data from boat sensors.
- Includes a polar diagram of the boat (S/Y Extasy - Beneteau First 40.7) for performance optimization.
- Useful during races for quick data access without manual calculations.

The app is developed in accordance with the [NMEA 0183 protocol v. 3.01.](https://www.plaisance-pratique.com/IMG/pdf/NMEA0183-2.pdf)

### Note: *This is the initial release and is still undergoing real-world tests and improvements. There is potential for additional features and optimization.*

## Installation

The app is still in development and not available on the App Store. You need an Apple developer account to install and test the app:
1. Clone the repository in Xcode.
2. Build and run the app on a simulator or a real device.

You will be able to use it for 7 days with free account and 1 year, or no-longer than you subscription expiration date, if you have paid developer subscription.

## Usage

Ensure you are on the same network as the device sending data on port 4950. The app will connect automatically and display sensor data on the relevant segments of the displays.

### Glossary

- DPT - Depth
- HDG - Heading (Magnetic Heading)
- SWT - Sea Water Temperature
- BSPD - Boat Speed through water (comes from the speed log)
- AWA - Apparent Wind Angle
- AWD - Apparent Wind Direction
- AWF - Apparent Wind Speed (or Apparent Wind Force)
- TWA - True Wind Angle
- TWD - True Wind Direction
- TWS - True Wind Speed (or True Wind Force)
- COG - Course Over Ground (comes from the GPS)
- SOG - Speed Over Ground (comes from the GPS)
- pSPD - Polar Speed (max speed of the boat according to the polar diagram under certain conditions)
- VMC - Velocity Made Good on course
- VMG - Velocity Made Good
- BTM - Bearing to Mark (or Bearing to Waypoint)
- DTM - Distance to Mark (or Distance to Waypoint)
- ETA - Estimated Time of Arrival
- TckETA - Estimated Time of Arrival to the next tack
- tD - Distance to Next Tack
- WPPOS - Position of the Waypoint
- BPOS - Position of the Boat

### Note: These values are used on S/Y Extasy but can be modified in the code as needed.

### *Multi Display*

<img width="400" alt="multi_display" src="https://github.com/user-attachments/assets/502eb7c4-01e1-47f8-abaa-e3b506c9b008">

The Multi Display shows various values and is persistent across sessions. Tap on different sectors to select desired values. If a value is already displayed, it will swap places with the new selection. An alarm is set for depth if it goes below 5 meters, which will be adjustable in future updates.

<img width="400" alt="multi_display_menu" src="https://github.com/user-attachments/assets/4c66f0ad-67c0-4c50-8f7f-50091a379805">

Alarm is set for the depth if it goes below 5 mtrs - the segment will be colored in red. It is fixed in the code but added in the settings menu in the future. Other alarms can be further developed to fit the needs of the person using it.

### *Ultimate Display*

<img width="400" alt="ultimate_display" src="https://github.com/user-attachments/assets/8b670670-c7b5-48b6-9b19-df2ac22ccdb8">

The Ultimate Display shows heading and wind angles. It includes settings, map, and waypoints menus accessible via buttons in the center. Corners are tappable and will chage different value via pop-up menu. Configuration of the view is persistent across sessions. 

<img width="400" alt="corners_menu" src="https://github.com/user-attachments/assets/5a2d73f1-08e4-4115-8511-bcc3b56354a1">

*Settings Menu*

<img width="400" alt="settings_menu" src="https://github.com/user-attachments/assets/f191794e-de58-4082-bb8f-70f266655026">

**Settings:** Configure wind speed units, read raw sensor data. Glossary and set alarms are under development.

*Map*

<img width="400" alt="map" src="https://github.com/user-attachments/assets/2212e0c1-3507-4281-9041-2d8dbfcbae29">

**Map:** Display boat and waypoint positions. It is not a professional nautical chart and it serves for information purposes only. It is not recommended for navigation.

*Waypoints*

<img width="400" alt="waypoints" src="https://github.com/user-attachments/assets/4dffbc0e-56ca-46cb-8361-42bec16044d2">

**Waypoints:** Add and manage waypoints with options to enter coordinates manually or capture boat's current coordinates.

<img width="400" alt="new_waypoint" src="https://github.com/user-attachments/assets/9153742a-8bcc-42b7-b1e7-baf3e05bfc34">

Once the waypoint has been selected as a target, a small green arrow will be shown on the Ultimate Display indicating the bearing to that mark (BTM). The map will be updated with the position of the mark as an yellow pyramid with its name. 

<img width="400" alt="mark_ultimate_displai" src="https://github.com/user-attachments/assets/504b4c57-369f-4dfb-969f-db72724fa394">

*BTM indicated by the small green arrow*

<img width="400" alt="map_mark" src="https://github.com/user-attachments/assets/6700bb7d-1f42-4b5e-aae9-39eca1f81669">

*Mark shown on the map*

In addition to those two, a hidden display view appears which can be accessed by sliding the multidisplay to the left. That reveals more information about the waypoint and the boat.

<img width="400" alt="vmc_view" src="https://github.com/user-attachments/assets/6b86a23d-d796-49bb-a346-b060e5f2f4ae">

The VMC sector will be colored green or red depending on the VMC value - green is better, red is worse. Tapping on some of the segments changes the units - DTW & tD can be seen in meters, boat lengths, nautical miles and cables.

Tapping on the WPPOS will toggle between waypoint (mark) and boat position.

Once the waypoint has been de-selected as target the view will disappear as well as the small green arrow and the position on the map, returning to the original view.

## **Documentation**

This is a navigation application project, featuring modular MVVM architecture. For a detailed look at the project's structure, refer to the [Software Architecture Diagram](https://github.com/bacataBorisov/ExtasyCompleteNavigation/blob/main/ExtasyCompleteNavigation/Docs/ExtasyCompleteNavigation-SA-Diagram.pdf).

## **Authors and Acknowledgment**

ExtasyCompleteNavigation was created by **[Vasil Borisov](https://github.com/bacataBorisov)**.

- [CocoaAsyncSocket](https://cocoapods.org/pods/CocoaAsyncSocket)
- Various articles from StackOverflow, Github and others

## **Changelog**

- **1.0.0:** Initial release
- **1.1.0:** - 2024-11-30
### Refactored
- Codebase refactored to improve modularity and maintainability.
- Introduced a more structured software architecture to align with best practices.
- Enhanced organization of files into logical layers (Data, Business, and Presentation).

No breaking changes. This update improves code quality for future development.

## **Contact**

If you have any questions or comments about the project, please contact **[bacata.borisov](https://github.com/bacataBorisov)**.
Open to suggestions for improvement, new features, or collaborations.


