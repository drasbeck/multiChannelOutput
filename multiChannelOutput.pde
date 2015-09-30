import ddf.minim.*;
import ddf.minim.ugens.*;

import javax.sound.sampled.*;

Minim channel12, channel34, channel56, channel78;

AudioOutput out12, out34, out56, out78;
AudioPlayer gallop12, gallop34, gallop56, gallop78;

int channelOut12 = 5; // hvor man sætter ud-kanalen til out 1&2
int channelOut34 = 3; // hvor man sætter ud-kanalen til out 3&4
int channelOut56 = 2; // hvor man sætter ud-kanalen til out 5&6
int channelOut78 = 4; // hvor man sætter ud-kanalen til out 7&8

Mixer.Info[] mixerInfo;

Oscil sine;
int activeMixer = -1;

void setup()
{
  size(512, 700, P3D);
  //textAlign(LEFT, TOP);

  channel12 = new Minim(this);
  channel34 = new Minim(this);
  channel56 = new Minim(this);
  channel78 = new Minim(this);
  
 
  mixerInfo = AudioSystem.getMixerInfo();

  gallop12 = channel12.loadFile("long_gallop12.wav");
  gallop34 = channel34.loadFile("long_gallop34.wav");
  gallop56 = channel56.loadFile("long_gallop56.wav");
  gallop78 = channel78.loadFile("long_gallop78.wav");
  
  //gallop12.setBalance(1f);
  gallop12.play();
  gallop34.play();  

  Mixer mixer12 = AudioSystem.getMixer(mixerInfo[channelOut12]);
  Mixer mixer34 = AudioSystem.getMixer(mixerInfo[channelOut34]);
  Mixer mixer56 = AudioSystem.getMixer(mixerInfo[channelOut56]);
  Mixer mixer78 = AudioSystem.getMixer(mixerInfo[channelOut78]);
  
  channel12.setOutputMixer(mixer12);
  channel34.setOutputMixer(mixer34);
  channel56.setOutputMixer(mixer56);
  channel78.setOutputMixer(mixer78);

  out12 = channel12.getLineOut(Minim.STEREO);
  out34 = channel34.getLineOut(Minim.STEREO);
  out56 = channel56.getLineOut(Minim.STEREO);
  out78 = channel78.getLineOut(Minim.STEREO);
}

void draw() {
  background(0);
  for (int i = 0; i < mixerInfo.length; i++)
    if (i == channelOut12 || i == channelOut34 || i == channelOut56 || i == channelOut78) 
    {
      fill(255);
      text("[" + i + "] " + mixerInfo[i].getName(), 15, 20+i*25, i);
    } else {
      fill(120);
      text("[" + i + "] " + mixerInfo[i].getName(), 15, 20+i*25, i);
    }
}