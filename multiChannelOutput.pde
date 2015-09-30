//-------------------------------------------------------------------------------------
// Velkommen til en processing sketch som laver output til flere kanaler end stereo.
// Baseret på input fra en Arduino med StandardFirmata sketchen.
//
// drasbeck.dk (cc by-sa) 2015
//-------------------------------------------------------------------------------------
// Noter:
// sample rate skal være 44100
// wav-filer skal være 16 bit, signed
//-------------------------------------------------------------------------------------
// Skema over hvilke kanaler der læser hvilken side af en lydfil
// 
//   | LEFT |RIGHT |
//   |------+------|
//   | OUT1 | OUT2 | 
//   | OUT3 | OUT4 |
//   | OUT5 | OUT6 |
//   | OUT7 |(OUT8)|
//
//-------------------------------------------------------------------------------------
// TODO
// Få styr på lydniveau hos i de forskellige kanaler.
//   - gøres med setGain på out12 eksempelvis.
// Få styr på sound scapes.
//   - i Ableton Live og Audacity.
//-------------------------------------------------------------------------------------

import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.signals.*;
import javax.sound.sampled.*;
import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;

Arduino arduino;

// sætter output kanalerne op
// output 1&2
Minim              channel12;
MultiChannelBuffer channelBuffer12;
AudioOutput        out12;
AudioPlayer        player12;
float              play12;
int channelOut12 = 5;

// output 3&4
Minim              channel34;
MultiChannelBuffer channelBuffer34;
AudioOutput        out34;
AudioPlayer        player34;
float              play34;
int channelOut34 = 3;

// output 5&6
Minim              channel56;
MultiChannelBuffer channelBuffer56;
AudioOutput        out56;
AudioPlayer        player56;
float              play56;
int channelOut56 = 2;

// output 7&8
Minim              channel78;
MultiChannelBuffer channelBuffer78;
AudioOutput        out78;
AudioPlayer        player78;
float              play78;
int channelOut78 = 4;

// Man gemmer lyddata samplere
Sampler ambient12, ambient34, ambient56, ambient78,
        gallop12, gallop34, gallop56, gallop78,
        hunde12, hunde34, hunde56, hunde78,
        jagtselskab12, jagtselskab34, jagtselskab56, jagtselskab78,
        groove12;

// Cooldowns
boolean gallopCooldown = true;
int gallopCooldownBegin;
int gallopCooldownDuration = 120000; // millisekunder aka 2 minutter

Mixer.Info[] mixerInfo;
float sampleRate = 44100f;

//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void setup()
{
  size(512, 800, FX2D);
  //textAlign(LEFT, TOP);

  // her sættes arduinoen op
  arduino = new Arduino(this, Arduino.list()[1], 57600);
  for (int i = 0; i <= 13; i++) {
    arduino.pinMode(i, Arduino.INPUT);
  }

  // hver kanal får en Minim til at lege med
  channel12 = new Minim(this);
  channel34 = new Minim(this);
  channel56 = new Minim(this);
  channel78 = new Minim(this);

  // og så sættes mixere op med hver deres line out.
  mixerInfo = AudioSystem.getMixerInfo();

  Mixer mixer12 = AudioSystem.getMixer(mixerInfo[channelOut12]);
  channel12.setOutputMixer(mixer12);
  out12 = channel12.getLineOut();

  Mixer mixer34 = AudioSystem.getMixer(mixerInfo[channelOut34]);
  channel34.setOutputMixer(mixer34);
  out34 = channel34.getLineOut();

  Mixer mixer56 = AudioSystem.getMixer(mixerInfo[channelOut56]);
  channel56.setOutputMixer(mixer56);
  out56 = channel56.getLineOut();

  Mixer mixer78 = AudioSystem.getMixer(mixerInfo[channelOut78]);
  channel78.setOutputMixer(mixer78);
  out78 = channel78.getLineOut();

  // til sidst sættes MultiChannelBuffere op.
  channelBuffer12 = new MultiChannelBuffer(1, 1024);
  channelBuffer34 = new MultiChannelBuffer(1, 1024);
  channelBuffer56 = new MultiChannelBuffer(1, 1024);
  channelBuffer78 = new MultiChannelBuffer(1, 1024);

  //  controlDebug();
  //  arduinoDebug();
  //  outputDebug();

  // gem alle lyde i hukommelsen
  loadSounds();
  println("[" + Math.round(millis() / 1000) + "] Sketch boottid " + millis() + " millisekunder.");
}

//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void draw() {
  background(0);
  stroke(255);

  // On screen Arduino debugging
  for (int i = 0; i <= 13; i++) {
    if (arduino.digitalRead(i) == Arduino.HIGH) {
      fill(243, 552, 117);
    } else {
      fill(84, 145, 158);
    }
    rect(420 - i * 30, 710, 20, 20);
  }
  noFill();
  for (int i = 0; i <= 5; i++) {
    ellipse(280 + i * 30, 750, arduino.analogRead(i) / 16, arduino.analogRead(i) / 16);
  }

  // draw the waveforms
  // the values returned by left.get() and right.get() will be between -1 and 1,
  // so we need to scale them up to see the waveform
  // note that if the file is MONO, left.get() and right.get() will return the same value
  noStroke();
  fill(255, 128);
  for (int i = 0; i < out12.bufferSize() - 1; i++) {
    float x1 = map(i, 0, out12.bufferSize(), 0, width);
    float x2 = map(i + 1, 0, out12.bufferSize(), 0, width);
    line(x1, 50 + out12.left.get(i) * 50, x2, 50 + out12.left.get(i + 1) * 50);
    line(x1, 150 + out12.right.get(i) * 50, x2, 150 + out12.right.get(i + 1) * 50);
  }
  rect(0, 0, out12.left.level() * width, 100);
  rect(0, 100, out12.right.level() * width, 100);

  for (int i = 0; i < out34.bufferSize() - 1; i++) {
    float x1 = map(i, 0, out34.bufferSize(), 0, width);
    float x2 = map(i+1, 0, out34.bufferSize(), 0, width);
    line(x1, 250 + out34.left.get(i) * 50, x2, 250 + out34.left.get(i + 1) * 50);
    line(x1, 350 + out34.right.get(i) * 50, x2, 350 + out34.right.get(i + 1) * 50);
  }
  rect(0, 200, out34.left.level() * width, 100);
  rect(0, 300, out34.right.level() * width, 100);

  for (int i = 0; i < out56.bufferSize() - 1; i++) {
    float x1 = map(i, 0, out56.bufferSize(), 0, width);
    float x2 = map(i + 1, 0, out56.bufferSize(), 0, width);
    line(x1, 450 + out56.left.get(i) * 50, x2, 450 + out56.left.get(i + 1) * 50);
    line(x1, 550 + out56.right.get(i) * 50, x2, 550 + out56.right.get(i + 1) * 50);
  }
  rect(0, 400, out56.left.level() * width, 100);
  rect(0, 500, out56.right.level() * width, 100);

  for (int i = 0; i < out78.bufferSize() - 1; i++) {
    float x1 = map(i, 0, out78.bufferSize(), 0, width);
    float x2 = map(i + 1, 0, out78.bufferSize(), 0, width);
    line(x1, 650 + out78.left.get(i) * 50, x2, 650 + out78.left.get(i + 1) * 50);
  }
  rect(0, 600, out78.left.level() * width, 100);

  // On screen output nummerering
  for (int i = 0; i < 7; i++) {
    text("Output #" + (i + 1), 440, ((i + 1) * 100) - 60);
  }

  //gallop trigger- og cooldown-funktionalitet
  if (arduino.digitalRead(7) == Arduino.HIGH && gallopCooldown) { //gallop startes når dPIN7 aktiveres
    gallop12.trigger();
    gallop34.trigger();
    gallop56.trigger();
    gallop78.trigger();
    gallopCooldown = false;
    gallopCooldownBegin = millis();
    println("[" + Math.round(millis() / 1000) + "] Gallop startet, klar igen om " + Math.round(gallopCooldownDuration / 1000) + " sekunder.");
  }
  if (gallopCooldownBegin + gallopCooldownDuration < millis() && !gallopCooldown) {
    gallopCooldown = true;
    println("[" + Math.round(millis() / 1000) + "] Gallop klar!");
  }
}

//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
// System test
void keyPressed() {
  if (key == ' ') {
    groove12.trigger(); // mellemrumstasten trigger en test på kanalerne 1 & 2
  }
}

//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void loadSounds() {
  play12 = channel12.loadFileIntoBuffer("long_gallop12.mp3", channelBuffer12);
  gallop12 = new Sampler(channelBuffer12, sampleRate, 1);
  gallop12.patch(out12);

  play34 = channel34.loadFileIntoBuffer("long_gallop34.mp3", channelBuffer34);
  gallop34 = new Sampler(channelBuffer34, sampleRate, 1);
  gallop34.patch(out34);

  play56 = channel56.loadFileIntoBuffer("long_gallop56.mp3", channelBuffer56);
  gallop56 = new Sampler(channelBuffer56, sampleRate, 1);
  gallop56.patch(out56);

  play78 = channel78.loadFileIntoBuffer("long_gallop78.mp3", channelBuffer78);
  gallop78 = new Sampler(channelBuffer78, sampleRate, 1);
  gallop78.patch(out78);

  play12 = channel12.loadFileIntoBuffer("groove.mp3", channelBuffer12);
  groove12 = new Sampler(channelBuffer12, sampleRate, 4);
  groove12.patch(out12);
  groove12.patch(out34);
  groove12.patch(out56);
  groove12.patch(out78);
}

//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
// DEBUGGING-værktøjer

// denne bid kode giver en liste over mulige outputs, samt alternativ farve på de valgte outputs.
void outputDebug() {
  for (int i = 0; i < mixerInfo.length; i++) {
    if (i == channelOut12  || i == channelOut34  || i == channelOut56  || i == channelOut78) {
      fill(255);
      text("[" + i + "] " + mixerInfo[i].getName(), 15, 20 + i * 25, i);
    } else {
      fill(120);
      text("[" + i + "] " + mixerInfo[i].getName(), 15, 20 + i * 25, i);
    }
  }
}

// denne bid kode giver en liste over tilgængelige seriel-forbindelser
void arduinoDebug() {
  print("DEBUG: Array over arduino-forbindelser: ");
  println(Arduino.list());
}

// denne bid kode lister hvilke former for kontrol minim har over output.
void controlDebug() {
  if (out12.hasControl(Controller.PAN)) {
    print("DEBUG: pan control        : out12 ja  |");
  } else {
    print("DEBUG: pan control        : out12 nej |");
  }
  if (out34.hasControl(Controller.PAN)) {
    print(" out34 ja  |");
  } else {
    print(" out34 nej |");
  }
  if (out56.hasControl(Controller.PAN)) {
    print(" out56 ja  |");
  } else {
    print(" out56 nej |");
  }
  if (out78.hasControl(Controller.PAN)) {
    println(" out78 ja");
  } else {
    println(" out78 nej");
  }

  if (out12.hasControl(Controller.VOLUME)) {
    print("DEBUG: volume control     : out12 ja  |");
  } else {
    print("DEBUG: volume control     : out12 nej |");
  }
  if (out34.hasControl(Controller.VOLUME)) {
    print(" out34 ja  |");
  } else {
    print(" out34 nej |");
  }
  if (out56.hasControl(Controller.VOLUME)) {
    print(" out56 ja  |");
  } else {
    print(" out56 nej |");
  }
  if (out78.hasControl(Controller.VOLUME)) {
    println(" out78 ja");
  } else {
    println(" out78 nej");
  }

  if (out12.hasControl(Controller.SAMPLE_RATE)) {
    print("DEBUG: sample rate control: out12 ja  |");
  } else {
    print("DEBUG: sample rate control: out12 nej |");
  }
  if (out34.hasControl(Controller.SAMPLE_RATE)) {
    print(" out34 ja  |");
  } else {
    print(" out34 nej |");
  }
  if (out56.hasControl(Controller.SAMPLE_RATE)) {
    print(" out56 ja  |");
  } else {
    print(" out56 nej |");
  }
  if (out78.hasControl(Controller.SAMPLE_RATE)) {
    println(" out78 ja");
  } else {
    println(" out78 nej");
  }

  if (out12.hasControl(Controller.BALANCE)) {
    print("DEBUG: balance control    : out12 ja  |");
  } else {
    print("DEBUG: balance control    : out12 nej |");
  }
  if (out34.hasControl(Controller.BALANCE)) {
    print(" out34 ja  |");
  } else {
    print(" out34 nej |");
  }
  if (out56.hasControl(Controller.BALANCE)) {
    print(" out56 ja  |");
  } else {
    println(" out56 nej |");
  }
  if (out78.hasControl(Controller.BALANCE)) {
    println(" out78 ja");
  } else {
    println(" out78 nej");
  }

  if (out12.hasControl(Controller.MUTE)) {
    print("DEBUG: mute control       : out12 ja  |");
  } else {
    print("DEBUG: mute control       : out12 nej |");
  }
  if (out34.hasControl(Controller.MUTE)) {
    print(" out34 ja  |");
  } else {
    print(" out34 nej |");
  }
  if (out56.hasControl(Controller.MUTE)) {
    print(" out56 ja  |");
  } else {
    print(" out56 nej |");
  }
  if (out78.hasControl(Controller.MUTE)) {
    println(" out78 ja");
  } else {
    println(" out78 nej");
  }

  if (out12.hasControl(Controller.GAIN)) {
    print("DEBUG: gain control       : out12 ja  |");
  } else {
    print("DEBUG: gain control       : out12 nej |");
  }

  if (out34.hasControl(Controller.GAIN)) {
    print(" out34 ja  |");
  } else {
    print(" out34 nej |");
  }

  if (out56.hasControl(Controller.GAIN)) {
    print(" out56 ja  |");
  } else {
    print(" out56 nej |");
  }

  if (out78.hasControl(Controller.GAIN)) {
    println(" out78 ja");
  } else {
    println(" out78 nej");
  }
}