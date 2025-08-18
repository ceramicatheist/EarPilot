# EarPilot

## Flying by ear

This app facilitates control of an airplane using audio cues.

The pilot in command is fully and solely responsible for the flight. Please keep [14 CFR 91.3(a)][1] and [14 CFR 91.13][2] in mind while using this app.

To run a working copy, download from Apple TestFlight: https://testflight.apple.com/join/BnY63rSB

### Display:

- Top edge: compass
- Right edge: rate of climb
- Center: artifical horizon (attitude indicator)
- Bottom: turn coordinator 

### To use:

- The pilot who will be flying by the audio cues should set up a suitable stereo headphone connection to the iPhone. AirPods worn underneath an aviation headset may work, as may pairing directly to a high-end headset with bluetooth and stereo.
- Choose voices you like. They should be clear and high-quality. Downloading some "Enhanced" or "Premium" voices from Apple is **highly** recommended (see the system Settings > Accessibility > Spoken Content > Voices > English > Voice.) Choosing distinct voices for bank and heading may be helpful.
- Secure the iPhone firmly in the airplane cockpit. Ram Mounts work well. Position it roughly vertically and as in line with the plane's axis as possible, i.e. in plane with the instrument panel. If it must be angled to the side a bit, adjust the "off-axis mount angle" setting to match.
- Turn off all the audio feature switches.
- Fly the plane straight and level. When stable in this attitude, tap the "zero pitch and roll" button. (Repeat this whenever necessary.)
- When the audio pilot would like to take control, turn on some or all of the audio features.

### Audio Features:

#### Speak Bank Angles

The plane's bank in degrees will be spoken, in five-degree increments, in the ear to the side the plane is banking toward. When level, "level" is spoken in the center.

If the plane is rolling *into* the bank (away from level), the speech will be in a **normal** tone. If the plane is rolling *out* of bank (toward level), the speech will have a **rising** tone, as if interrogative.

If the plane is *slipping* (turn coordinator ball to the *inside* of the turn), the voice will be pitched **deeper**. If the plane is *skidding* (turn coordinator ball to the *outside* of the turn), the voice will be pitched **higher**.

#### Beep Pitch Angle

Plays MIDI musical notes proportional to the pitch of the plane.

When level, plays concert A, using a bell sound.

When pitched down, plays lower notes, one semitone per three degrees, using a synthetic string instrument.

When pitched up, plays higher notes, one semitone per three degrees, using a wind instrument.

**Bug**: under unknown circumstances, Apple's MIDI synth sometimes gives up, and starts playing a plain sinewave instead of the included MIDI instruments. Killing and restarting the app is the only known fix. 

#### Speak Compass Points

In turns, the nearest cardinal compass direction will be periodically spoken, coming from that direction using spatial audio.

E.g.: when turning to northeast by north, "NORTH" will be spoken, apparently from the front-left. Turning slightly eastward to northeast by east, and "EAST" will be spoken from the right. Continuing the turn to due east will cause "EAST" to sound directly from the front/center.

When holding a constant heading, heading will not be spoken.

While turning, heading will be spoken more frequently as the rate of turn increases.

## License

This source code is provided for educational review only. All other rights are reserved. Copyright 2025 Eclecticode LLC / Rogers George

email <rgeorge@eclecticode.com> with comments and questions

[1]: https://www.ecfr.gov/current/title-14/part-91/section-91.3#p-91.3(a)
[2]: https://www.ecfr.gov/current/title-14/section-91.13
