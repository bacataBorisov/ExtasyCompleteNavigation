#Extasy Complete Navigation


## Overview

**ExtasyCompleteNavigation** is a modular sailing navigation app designed to provide accurate navigation data using NMEA sentences and advanced processing logic.

This internal README outlines the app's architecture, key modules, and instructions for developers working on this project.

---

## Project Structure

├── Core
│   ├── Constants.swift          # Centralized constants for the app
│   ├── Extensions.swift         # Reusable Swift extensions
│   ├── GeometryProvider.swift   # Utility for geometry calculations
│   └── UtilsNMEA.swift          # Helper functions for NMEA data parsing
├── Managers
│   └── NavigationManager.swift  # Handles data flow between UDPHandler and NMEAParser
├── Model
│   ├── CompassData.swift        # Data model for compass readings
│   ├── GPSData.swift            # Data model for GPS readings
│   ├── HydroData.swift          # Data model for hydro-related data
│   ├── VMGData.swift            # Data model for VMG calculations
│   └── WindData.swift           # Data model for wind-related data
├── Modules
│   ├── CompassProcessor.swift   # Processes compass-related calculations
│   ├── GPSProcessor.swift       # Processes GPS data
│   ├── HydroProcessor.swift     # Processes hydro-related data
│   ├── VMGProcessor.swift       # Performs VMG calculations
│   └── WindProcessor.swift      # Processes wind-related data
├── View
│   ├── MultiDisplay             # Contains reusable UI components for data displays
│   ├── UltimateView             # The main navigation interface
│   ├── VMGView                  # VMG-specific view components
│   ├── Waypoints                # UI for managing waypoints
│   └── Common                   # Reusable shared components
├── ViewModel
│   ├── SettingsMenuViewModel.swift  # Manages settings menu data
│   └── VMGViewModel.swift           # Manages data for VMG views

---

## Architecture

The project follows a **modular MVVM architecture**, ensuring scalability and ease of maintenance. Here's how the layers are defined:

### **Data Layer**
- **Responsibilities:** Data retrieval, parsing, and persistence.
- **Files:**
  - Models: `CompassData.swift`, `GPSData.swift`, `HydroData.swift`, `VMGData.swift`, `WindData.swift`
  - Utilities: `DiagramLoader.swift`, `KalmanFilter.swift`, `MathUtilities.swift`
  - Networking: `UDPHandler.swift`

### **Domain Layer**
- **Responsibilities:** Core business logic and computations.
- **Files:**
  - Processors: `CompassProcessor.swift`, `GPSProcessor.swift`, `HydroProcessor.swift`, `WindProcessor.swift`, `VMGProcessor.swift`
  - Business Logic: `VMGCalculator.swift`

### **Presentation Layer**
- **Responsibilities:** UI representation and state management.
- **Files:**
  - ViewModels: `VMGViewModel.swift`, `SettingsMenuViewModel.swift`
  - Views: `UltimateView/`, `VMGView/`, `Waypoints/`, `Common/`

---

## Key Modules and Features

### **Wind Processing**
- Handles real-time wind data from NMEA sentences.
- Smoothens data using Kalman filtering.

### **VMG Calculations**
- Computes Velocity Made Good (VMG) using polar diagrams.
- Manages waypoint calculations.

### **Hydro Data**
- Processes depth, temperature, and speed log data.

### **UDP Networking**
- Receives NMEA sentences over UDP.
- Feeds data into `NMEAParser`.

---

## Instructions for Developers

... continue working here ...
