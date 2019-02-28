# Guisynth

Files for the SuperCollider IDE,
Development of a Liveperformance-Tool.

Synthesizer with Gui and MVC-Implementation

Files for Midi-Control can be loaded if uncommented in the main file:
NanoCtl_Live01.scd  for Korg NanocontrolI 
CC Midi-Channels for the controllers are stored in Arrays and can be adepted
<code>~nc.sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];
	~nc.knobNumbers = [33, 34, 35, 36, 37, 38, 39, 40];
</code>
<code>
	~nc.button1Numbers[0] = [48, 49, 50, 51, 52, 53, 54, 55];
	~nc.button2Numbers[0] = [64, 65, 66, 67, 68, 69, 70, 71];
	~nc.button3Numbers[0] = [72, 73, 74, 75, 76, 77, 78, 79];
</code>

The file Cloudsynth3.scd is for Cloudspeakers
which are in the same network (see http://cloudspeaker.zhdk.ch)

the folder "/sounds" should be filled with soundfiles.
The sounds are loaded in the moduls: granulator1, granulator2, sampler

Select your SoundDevice in the Main File:
<code>o.device = "JackRouter";</code>

More Information about SuperCollider:
[SuperCollider](https://supercollider.github.io/)

	