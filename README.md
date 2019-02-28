# Guisynth

Files for the SuperCollider IDE,
Development of a Liveperformance-Tool.

Synthesizer with Gui and MVC-Implementation

Files for Midi-Control can be loaded if uncommented in the main file:<br />
NanoCtl_Live01.scd  for Korg Nanocontrol1<br />
CC Midi-Channels for the controllers are stored in Arrays and can be adapted:<br />
<code>~nc.sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];</code><br />
<code>~nc.knobNumbers = [33, 34, 35, 36, 37, 38, 39, 40];</code><br />

<code>~nc.button1Numbers[0] = [48, 49, 50, 51, 52, 53, 54, 55];</code><br />
<code>~nc.button2Numbers[0] = [64, 65, 66, 67, 68, 69, 70, 71];</code><br />
<code>~nc.button3Numbers[0] = [72, 73, 74, 75, 76, 77, 78, 79];</code><br />


The file Cloudsynth3.scd is for Cloudspeakers<br />
which are in the same network (see http://cloudspeaker.zhdk.ch)<br />

a folder "sounds" should be created and filled with soundfiles (wav-files).<br />
The sounds are loaded in the moduls: granulator1, granulator2, sampler ...<br />
Further Soundmoduls: a simple addative Synth, and a extended Synth which is playing granulated textures<br />

Select your SoundDevice in the Main File:<br />
e.g.:<code>o.device = "JackRouter";</code>

More Information about SuperCollider:<br />
[SuperCollider](https://supercollider.github.io/)

	
