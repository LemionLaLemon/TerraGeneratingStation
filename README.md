# Terra Generating Station
**Plant fusion nuclear banana power turbine girdler deuterium plant power**

(yes, that is supposed to be nonsense, I speak english very well.)

<img alt="Control Room" src="https://dss-api.interatom.online/api/documents/499/file" />
<img alt="Plasma" src="https://dss-api.interatom.online/api/documents/497/file" />
<img alt="Control Room Layout" src="https://dss-api.interatom.online/api/documents/496/file"/ >

## What is Terra Generating Station?
Terra Generating Station is a nuclear fusion power plant utilising a Tokamak design reactor. 

## What's completed now?
"Back end":
- Lumped Parameter Nodal Network Simulator
- DX1000 Paperless Chart Recorder
- HMI Flow Diagram systems
- Annunciation Panel systems(the lights that blink and make loud noises)
- Tons more controls and monitoring instrumentation (edgewise gauges, collared pushbuttons, SBM control breaker, pilot lamps, reset pushbuttons)
- Vacuum Controls (Roughing Pump Vacuums and Turbo Molecular Pumps)
- Magnet Controls (Toroidal Field, Equilibrium Field aka Poloidal Field, Central Solenoid, Vertical Stability)
- Neutral Beams
- Plasma visual inside the core
- Simulation controls

"Front end":
- Blending up the bananas to get mush
- Distilling mush to get water
- Separating water using the Girdler process for D2O (Heavy Water) and H2O (Light Water)
- Electrolysing D2O to separate D2 from O
- Pumping down the tokamak
- Ramping magnets up to produce a field
- Changing current on Central Solenoid induces a current in the plasma
- Injecting neutral D2 beams into the core
- Plasmas

## What's to come?
- Nuclear fusion...in the nuclear fusion reactor
- Literally any of the turbine systems (secondary)

## How do I run this?
Godot has very generously packaged everything into either a .x86_64 (linux) or a .exe (windows) so all you need to do is
1. Downloads the appropriate executable for your system (sorry mac users!)
2. Double click to run

Optionally, a web build exists on [Interatom](https://terrageneratingstation.interatom.online/). It is currently on version 0.2.0. Visuals may look slightly worse, so this isn't really intended.

## Controls
Terra Generating Station locks your cursor by default.
- E (hold) to zoom into equipment, and mouse scroll to adjust zoom distance
- F to toggle cursor lock
- Right click in cursor locked mode to bring up arm (for point and shout human performance tools)
- Right click in cursor unlocked mode to temporarily lock cursor (allows you to move the camera)

## Procedures
Standard Operating Procedures used to operate the plant:

- [SOP-FUEL-OPS: Fuel Operations](procedures/SOP-FUEL-OPS.pdf)
- [SOP-REAC-OPS: Plasma Operations](procedures/SOP-REAC-OPS.pdf)

System Descriptions outlining a system:

- [SD-SIM-CTRL: Simulation Controls](System%20Descriptions/SD-SIM-CTRL.pdf)

Annunciator Response Procedures with explainations of the alarms:

- [ARP-601: Center Panel](Annunciator%20Response%20Procedures/ARP-601.pdf)
- [ARP-602: Left Panel](Annunciator%20Response%20Procedures/ARP-602.pdf)
- [ARP-603: Right Panel](Annunciator%20Response%20Procedures/ARP-603.pdf)

A mirror of these documents are also maintained on Lemion Industries InterATOM's Document Search Service:

- [Standard Operating Procedures](https://dss.interatom.online/Terra%20Generating%20Station/SOPs)

- [System Descriptions](https://dss.interatom.online/Terra%20Generating%20Station/SDs)

- [Annunciator Response Procedures](https://dss.interatom.online/Terra%20Generating%20Station/ARPs)