# Guisynth

Files for the SuperCollider IDE for MAC, also a Version for Linux exists
Development of a Liveperformance-Tool. It consists of a a mixer, soundmoduls, effects (reverb, delay, distortion), aux channel for audiostream via raspberry pi, possibility to use Cloudspeakers remotly

### Synthesizer with Gui and MVC-Implementation

Files for Midi-Control can be loaded if uncommented in the main file: _"NanoCtl_Live01.scd"_ for Korg Nanocontrol1<br />
CC Midi-Channels for the controllers are stored in Arrays and can be adapted:
```~nc.sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];
~nc.knobNumbers = [33, 34, 35, 36, 37, 38, 39, 40];

~nc.button1Numbers[0] = [48, 49, 50, 51, 52, 53, 54, 55];
~nc.button2Numbers[0] = [64, 65, 66, 67, 68, 69, 70, 71];
~nc.button3Numbers[0] = [72, 73, 74, 75, 76, 77, 78, 79];
```


The file Cloudsynth3.scd is for Cloudspeakers
which are in the same network see: http://cloudspeaker.zhdk.ch

a folder "sounds" should be created and filled with soundfiles (wav-files).
The sounds are loaded in the moduls: granulator1, granulator2, sampler ...
Further Soundmoduls: a simple additive Synth, and a extended Synth which is playing granulated textures

Start the main file with Supercollider IDE, (evaluate the File e.g. with CMD - RETURN)

Select your SoundDevice in the Main File:
e.g.:`o.device = "JackRouter";`

More Information about [SuperCollider:](https://supercollider.github.io/)


