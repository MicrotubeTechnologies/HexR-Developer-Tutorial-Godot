# HexR Godot Integration — Developer Tutorial ℹ️

A Godot 4 tutorial project for the **HexR** haptic glove, running on **Meta Quest** and
**PICO** through OpenXR. It ships three ready-to-run scenes and the **HexR Godot addon**, so you
can feel haptics in a headset before writing any code of your own.

> [!NOTE]
> The same glove works from **Unity** and **Python** too. See the official
> [HexR documentation](https://microtube.tech/hexr-docs), which also covers this addon under **Godot**.

---

## 📑 Contents

| Section | What's inside |
|---|---|
| [🚀 Getting Started](#-getting-started) | Prerequisites, clone and open, export to a headset, Bluetooth permissions |
| [🧤 Addon Reference](#-addon-reference) | The `HexR` autoload, gloves, Pressure Controllers, the haptics calls |
| [🧩 Components](#-components) | The nodes you actually add to a scene |
| [🎬 Demo Scenes](#-demo-scenes) | What each tutorial scene shows, and how |
| [📡 HexR Remote](#-hexr-remote) | Watch and control the headset from the HexR Companion |
| [📄 License](#-license) | MIT, plus third-party notices |

---

## 🚀 Getting Started

### ✅ Prerequisites

| Requirement | Details |
|---|---|
| **Godot 4.6 or newer** | Tested on **4.7.2**. The standard build; .NET is not needed. |
| **Android export templates** | Editor → Manage Export Templates → Download. |
| **Android SDK and JDK 17** | Editor Settings → Export → Android. Godot's [Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) walks through it. |
| **A headset** | Meta Quest 2, 3, 3S or Pro, or PICO 4 / 4 Ultra, in developer mode. Run with a glove on a Quest 3 so far; the PICO build exports but has not been run on a headset yet. |
| **A HexR Glove 2.0** | Charged and switched on. Do **not** pair it in the headset's Bluetooth settings. |

Already in the project, pinned:

| Addon | Version | What for |
|---|---|---|
| `addons/hexr` | 0.1.0 | The HexR addon (this is what you add to your own projects) |
| `addons/godotopenxrvendors` | 5.1.0 | Meta and PICO OpenXR support |
| `addons/godot-xr-tools` | 4.5.2 | Start-up, and the optional pick-up example |

### 📥 Setup

1. **Clone this repository:**

   ```bash
   git clone https://github.com/MicrotubeTechnologies/HexR-Developer-Tutorial-Godot.git
   ```

2. **Open the project in Godot 4.6+** (Import → `project.godot`). The first import takes a minute.

3. **Install the Android build template** — *Project → Install Android Build Template*. Both
   the OpenXR Vendors plugin and the HexR Bluetooth plugin need Gradle builds.

4. **Export** — *Project → Export*, pick **Quest** or **PICO**, then *Export Project*, or
   plug the headset in and press the **Remote Deploy** (Android) button in the editor's toolbar.

5. **Open `scenes/`** to explore the tutorial scenes — start with *1_basic_tutorial*.

### 📶 Bluetooth Permissions

The glove is found over Bluetooth. The first time you press **Connect**, the headset asks:

| Headset | Permission | Answer |
|---|---|---|
| Meta Quest (Android 12+) | **Nearby devices** | Allow |
| PICO 4 (Android 10) | **Location** | Allow, and keep the system **Location** switch on |

> [!WARNING]
> Without the permission the glove is never found. To change your answer later:
> Quest **Settings → Privacy & Safety → App Permissions**, PICO **Settings → Apps → HexR Godot Tutorial**.

<details>
  <summary>📦 Adding HexR to another Godot project</summary>

<br>

1. Download `HexR-Godot-<version>.zip` from the HexR-Godot releases and unzip it into your
   project, so you have `res://addons/hexr/`.
2. **Project → Project Settings → Plugins** → enable **HexR**. This adds the `HexR` autoload and
   names physics layers 20 (`hexr_touch`) and 21 (`hexr_interactable`).
3. **Project → Tools → HexR → Create HexR Rig** in your XR scene (it adds an `XROrigin3D` if
   there is none). Then **Add HexR Menu** for the floating menu.
4. Open the **HexR** dock → **Setup** → *Check project and open scene*, and press **Fix** on
   anything red.
5. Turn on **Use Gradle Build** in your Android export preset.

</details>

---

## 🧤 Addon Reference

The `HexR` autoload owns both gloves and their Bluetooth link. Scenes bring their own rig.

```gdscript
# Connect (asks for the Bluetooth permission first where needed; safe to call any time).
HexR.connect_hand(HexRTypes.Hand.LEFT)
HexR.glove_connected.connect(func(hand): print(HexRTypes.hand_name(hand), " connected"))

# Press the left index at 80% through the hand's Pressure Controller...
HexR.controller(HexRTypes.Hand.LEFT).custom_single_haptics(HexRTypes.Finger.INDEX, true, 0.8, 1.0, true)

# ...or build the bytes yourself and send them.
var g := HexR.left
g.bt_send(g.haptics.hexr_vibration(HexRTypes.Finger.PALM, true, 18.0, 0.7))
g.release_all_channels()
```

<details>
  <summary>🔍 The haptics calls and their ranges</summary>

<br>

| Call (on `HexR.left.haptics` / `HexR.right.haptics`) | Opcode | Parameters |
|---|---|---|
| `hexr_pressure(finger, on, intensity, speed)` | 0x04 | intensity 0.1–1 (≈15–50 kPa), speed 0.1–1 |
| `hexr_vibration(finger, on, frequency, intensity)` | 0x07 | 0.1–40 Hz |
| `hexr_pulse(finger, on, frequency, intensity, count)` | 0x08 | count 1–1000 |
| `hexr_vibration_ramped(finger, on, frequency, intensity, peak_ratio, speed, end_intensity)` | 0x09 | 0.1–2 Hz, peak 0.2–0.8 |
| `hexr_pulse_ramped(…, count, end_intensity)` | 0x0A | |

Out-of-range values are clamped, not rejected. Channels are `HexRTypes.Finger`: `THUMB`,
`INDEX`, `MIDDLE`, `RING`, `PINKY`, `PALM`. The bytes are identical to the Unity package's.

| `HexRPressureController` (`HexR.controller(hand)`) | |
|---|---|
| `single_index_haptic(intensity)` … `single_palm_haptic` | One channel; only while the hand is near something |
| `remove_index_haptics()` … | Release one channel |
| `custom_single_haptics(finger, on, intensity, speed, bypass_hand_check)` | Any channel, optionally skipping the hand-near check |
| `trigger_all_haptics_increase`, `trigger_pinch_pressure`, `trigger_all_vibrations` | Several channels |
| `remove_all_haptics()`, `remove_all_vibrations()` | Release everything |
| `strength_to_intensity(strength)` | The components' 10–60 scale to 0.1–1 |

</details>

---

## 🧩 Components

Add these to your scene; none needs an interaction toolkit.

| Node | Base | What it does |
|---|---|---|
| `HexRRig` | Node3D | Under your `XROrigin3D`: both tracked hands (touch points on the fingertips and palm) and both Pressure Controllers |
| `HexRGrabbable` | Area3D | Child of a `RigidBody3D`: pinch or palm grab, each touching finger pressed |
| `HexRPhysicalButton` | Area3D | A button pressed by a fingertip; the finger feels it |
| `HexRSpecialHaptics` | Area3D | Zones: custom vibration, custom pressure, fountain, rain drop, heart beat, hand squeeze |
| `HexRProximityCheck` | Area3D | Opens the hand-near check for code-driven haptics |
| `HexRUsable` | Area3D | Signals when chosen fingers curl and uncurl |
| `HexRInteractableHaptics` | Node | Child of an XR Tools pickable: pressure while held, following the grip |
| `HexRFloatingMenu` | Node3D | The HexR panel: connect, battery, live haptics readout |
| `HexRRemote` | Node | The phone link (see below) |

---

## 🎬 Demo Scenes

<details>
  <summary>1 · Basic Tutorial</summary>

<br>

| Object | How the haptics are added | What you feel |
|---|---|---|
| **Foam** | `HexRGrabbable`, palm grab, strength 20 | A soft press on each finger around it |
| **Key** | `HexRGrabbable`, pinch grab, strength 40 | A firm pinch on thumb and finger |
| **Torch** | `HexRGrabbable` + `HexRSpecialHaptics` (custom vibrations, 25 Hz) on the flame | Holding it, then a buzz when a fingertip enters the flame |
| **Button** | `HexRPhysicalButton` → the bulb's `toggle()` | A press on the index while it is down |
| **XR Tools ball** | XR Tools `pickable.tscn` + `HexRInteractableHaptics` | Pressure that follows how hard you squeeze |

</details>

<details>
  <summary>2 · Hospital Tutorial</summary>

<br>

| Object | How the haptics are added | What you feel |
|---|---|---|
| **Wrist and neck** | `HexRSpecialHaptics`, heart beat | A pulse under the fingertips resting there |
| **Pulse button** | `HexRPhysicalButton` → `heartbeat_toggle.gd` | Switches every pulse between regular and irregular |
| **Heart** | Heart beat zone (palm included) + hand squeeze zone, `squeezing_heart.gd` | It beats in your palm; squeeze and it races |

</details>

<details>
  <summary>3 · Water Effects</summary>

<br>

| Object | How the haptics are added | What you feel |
|---|---|---|
| **Fountain** | `HexRSpecialHaptics`, fountain | Running water: 18 Hz on the fingers in the jet |
| **Rain cloud** | `HexRSpecialHaptics`, rain drop | Random drops while your palm faces up under it |

</details>

The scenes are built by `tools/build_scenes.gd` (`godot --headless --path . -s res://tools/build_scenes.gd`)
so their layout and wiring can be read in one place. Edit the `.tscn` files freely; re-running
the builder overwrites them.

---

## 📡 HexR Remote

The rig includes `HexRRemote`. With a phone running the **HexR Companion** on the same Wi-Fi,
its **Headsets** tab finds this app, shows both gloves' state and pressures, can connect and
release them, switch between the three scenes, run the *Reset the props* and *Toggle heartbeat*
commands, and show the headset's view and sound (the wearer accepts a capture prompt once).

> [!WARNING]
> HexR Remote is local-network only and not authenticated: anyone on the same Wi-Fi with a
> HexR Remote client can control the gloves. Bring a dedicated router to events.

---

## 📄 License

MIT, see [LICENSE](LICENSE). The addons keep their own licences (HexR: MIT; Godot OpenXR
Vendors: MIT; Godot XR Tools: MIT), and the hand models are from Godot's demo projects (MIT).
See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). The Microtube logo in `icon.png` is a
Microtube Technologies mark and is not covered by the MIT licence; use your own icon in your app.
