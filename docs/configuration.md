# Configuration

[Back to README](../README.md)

Every operator template has the same starting values. Choose the script in G HUB before editing it; installation does not select or activate a script.

## Basic settings

| Setting | Default | Effect |
| :--- | :---: | :--- |
| `RcCustomStrength` | `0` | Downward movement applied on each vertical step. |
| `HorizontalStrength` | `0` | Negative moves left; positive moves right. |

With both values at zero, there is no scripted mouse movement. Use integer values. Calibration depends on the weapon, attachments, DPI and sensitivity. Keep those conditions consistent when comparing changes, and change one value at a time.

The pack contains no per-weapon recoil measurements, automatic operator detection or automatic sensitivity conversion.

## Advanced controls

| Setting | Default | What it controls |
| :--- | :---: | :--- |
| `EnableRCS` | `true` | Enables the movement logic. Zero strengths still produce no movement. |
| `RecoilControlMode` | `"Custom"` | Uses the basic vertical strength. Other modes use their internal preset value. |
| `VerticalFrequency` | `2` | Vertical movement every two firing-loop iterations. |
| `HorizontalFrequency` | `4` | Horizontal movement every four firing-loop iterations. |
| `DelayRate` | `7` | Requested sleep per firing iteration, in milliseconds. |
| `RequireToggle` | `true` | Requires the configured lock key before entering the aiming loop. |
| `ToggleKey` | `"CapsLock"` | Lock key used for activation. |

Normally leave these unchanged. Altering a frequency or delay changes the effect of existing strength values. Sleep requests are not precise real-time guarantees.

## Firing behavior

- With the default toggle enabled, Caps Lock must be on before entering the aim loop.
- Movement runs while right mouse and left mouse are held.
- Vertical and horizontal counters reset when a burst begins.
- Releasing either fire or aim exits the firing loop.
- While aiming without firing, the script requests a 1 ms pause between checks.
- Caps Lock is not continuously rechecked inside the aiming/firing loops. Release aim before changing its state.

The two firing branches remain separate. The movement is constant and repeating, not an adaptive sequence for individual bullets or random recoil.

## Keeping your changes

Matching operator names are skipped during installation; your existing script is not reset to the neutral template. Uninstall also preserves edited files. Back up your calibration before making further changes. See [setup and recovery](setup.md#backups-and-recovery).
