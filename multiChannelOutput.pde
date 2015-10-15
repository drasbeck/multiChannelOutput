//-------------------------------------------------------------------------------------
// Velkommen til en processing sketch som laver output til flere kanaler end stereo.
// Baseret på input fra en Arduino med StandardFirmata sketchen.
//
// drasbeck.dk (cc by-sa) 2015
//-------------------------------------------------------------------------------------
// Noter:
// sample rate skal være 44100
// wav-filer skal være 16 bit, signed
// tilsyneladende forsvinder .looping i ny og næ?
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
//   - gøres med setGain på out12 eksempelvis -- når vi har højttalerne.
// Få styr på sound scapes.
//   - i Ableton Live og Audacity.
//   - se under samplere hvilke vi mangler.  
// Lav random afspilning af lydfil AKA birdOfTheMinute
// Lav fadeIn, fadeOut, fadeCross.
// Lav klasser, så det bliver nemmere at sætte op. Til en anden god gang.
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
float              play12;
int channelOut12 = 6;

// output 3&4
Minim              channel34;
MultiChannelBuffer channelBuffer34;
AudioOutput        out34;
float              play34;
int channelOut34 = 4;

// output 5&6
Minim              channel56;
MultiChannelBuffer channelBuffer56;
AudioOutput        out56;
float              play56;
int channelOut56 = 3;

// output 7&8
Minim              channel78;
MultiChannelBuffer channelBuffer78;
AudioOutput        out78;
float              play78;
int channelOut78 = 5;


// Man gemmer lyddata samplere
Sampler
  ambience12, ambience34, ambience56, ambience78, // alle
  fugl11, fugl12, fugl13, fugl14, fugl15, fugl16, fugl17, // fugl type, kanal
  fugl21, fugl22, fugl23, fugl24, fugl25, fugl26, fugl27, // f.eks. fugl21 =
  fugl31, fugl32, fugl33, fugl34, fugl35, fugl36, fugl37, // spætmejse på kanal 1
  fugl41, fugl42, fugl43, fugl44, fugl45, fugl46, fugl47, // 
  morgenmodet12, // 1 -- done ???
  jagten12, jagten34, jagten56, jagten78, // alle -- IKKE done - mangler gallop-plask og gallop-træbro
  slottene78, // 7 -- IKKE done - skal mastereres
  gudKongenOgGeometrien56, // 6 - done - hvis musikken spiller
  hundeneBelonnes34, // 4 - IKKE done - mangler lyden af hunde der æder
  groove1, groove2, groove3, groove4, groove5, groove6, groove7; // 1 & 2 -- bruges til at teste en helt anden type lyd

// Forbrug
int jagten;
int morgenmodet;
int slottene;
int gudKongenGeometrien;
int hundeneBelonnes;


// Cooldowns
int warmUp = 5000; // normalt 60000
boolean warmUpDone = false;
boolean jagtenCooldown = true;
int jagtenCooldownBegin;
int jagtenCooldownDuration = 5000; // normalt 120000 millisekunder aka 2 minutter
int hvertTiendeSekund;

Mixer.Info[] mixerInfo;
float sampleRate = 44100f;

//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void setup()
{
  size(512, 800, P2D);
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
  birdOfTheMinute();

  // startup tekst
  println("[" + Math.round(millis() / 1000) + "] multiChannelOutput");
  println("[" + Math.round(millis() / 1000) + "] build 15A282a");
  println("[" + Math.round(millis() / 1000) + "] boottid " + millis() + " millisekunder.");
  println("[" + Math.round(millis() / 1000) + "] Varmer PIR-sensorerne op, det tager 60 sekunder");
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
  if (warmUp < millis()) {
    if (!warmUpDone) {
      println("[" + Math.round(millis() / 1000) + "] PIR-sensorerne er klar");
      warmUpDone = true;
    }
    //jagten trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(7) == Arduino.HIGH && jagtenCooldown) { //jagten startes når dPIN7 aktiveres
/*    
      jagten12.trigger();
      jagten34.trigger();
      jagten56.trigger();
      jagten78.trigger();
*/

      // Cooldown mekanisme
      jagtenCooldown = false;
      jagtenCooldownBegin = millis();
      jagten++;
      println("[" + Math.round(millis() / 1000) + "] Jagten startet " + jagten + " gang(e), klar igen om " + Math.round(jagtenCooldownDuration / 1000) + " sekunder.");
    }
    if (jagtenCooldownBegin + jagtenCooldownDuration < millis() && !jagtenCooldown) {
      jagtenCooldown = true;
      println("[" + Math.round(millis() / 1000) + "] Jagten klar!");
    }
  }

  if (millis() > hvertTiendeSekund + 9999) {
    hvertTiendeSekund = millis();
    //birdOfTheMinute();
  }
  text("FPS: " + nfs(frameRate, 2, 1), 439, 20);
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void birdOfTheMinute() {
  
  int fugl = (int)Math.ceil(Math.random() * 4);
  int kanal = (int)Math.ceil(Math.random() * 7);
  println("[" + Math.round(millis() / 1000) + "] Fugl: 0" + fugl);
  println("[" + Math.round(millis() / 1000) + "] Kanal: " + kanal);
  Fugl minutFugl = new Fugl(fugl, kanal);
  minutFugl.load();

}








//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void loadSounds() {
/*
  play12 = channel12.loadFileIntoBuffer("0. Ambience12.wav", channelBuffer12);
  ambience12 = new Sampler(channelBuffer12, sampleRate, 1);
  ambience12.patch(out12);

  play34 = channel34.loadFileIntoBuffer("0. Ambience34.wav", channelBuffer34);
  ambience34 = new Sampler(channelBuffer34, sampleRate, 1);
  ambience34.patch(out34);

  play56 = channel56.loadFileIntoBuffer("0. Ambience56.wav", channelBuffer56);
  ambience56 = new Sampler(channelBuffer56, sampleRate, 1);
  ambience56.patch(out56);

  play78 = channel78.loadFileIntoBuffer("0. Ambience78.wav", channelBuffer78);
  ambience78 = new Sampler(channelBuffer78, sampleRate, 1);
  ambience78.patch(out78);
*/

/*
  play12 = channel12.loadFileIntoBuffer("morgenmodet12.mp3", channelBuffer12);
   morgenmodet12 = new Sampler(channelBuffer12, sampleRate, 1);
   morgenmodet12.patch(out12);
*/

/*
  play56 = channel56.loadFileIntoBuffer("Sanktus.wav", channelBuffer56);
  gudKongenOgGeometrien56 = new Sampler(channelBuffer56, sampleRate, 1);
  gudKongenOgGeometrien56.patch(out56);
*/

/*
  play12 = channel12.loadFileIntoBuffer("jagten12.mp3", channelBuffer12);
  jagten12 = new Sampler(channelBuffer12, sampleRate, 1);
  jagten12.patch(out12);

  play34 = channel34.loadFileIntoBuffer("jagten34.mp3", channelBuffer34);
  jagten34 = new Sampler(channelBuffer34, sampleRate, 1);
  jagten34.patch(out34);

  play56 = channel56.loadFileIntoBuffer("jagten56.mp3", channelBuffer56);
  jagten56 = new Sampler(channelBuffer56, sampleRate, 1);
  jagten56.patch(out56);

  play78 = channel78.loadFileIntoBuffer("jagten78.mp3", channelBuffer78);
  jagten78 = new Sampler(channelBuffer78, sampleRate, 1);
  jagten78.patch(out78);
*/

  // test af kanaler
/*
  play12 = channel12.loadFileIntoBuffer("grooveLeft.wav", channelBuffer12);
  groove1 = new Sampler(channelBuffer12, sampleRate, 4);
  groove1.patch(out12);

  play12 = channel12.loadFileIntoBuffer("grooveRight.wav", channelBuffer12);
  groove2 = new Sampler(channelBuffer12, sampleRate, 4);
  groove2.patch(out12);

  play34 = channel34.loadFileIntoBuffer("grooveLeft.wav", channelBuffer34);
  groove3 = new Sampler(channelBuffer34, sampleRate, 4);
  groove3.patch(out34);

  play34 = channel34.loadFileIntoBuffer("grooveRight.wav", channelBuffer34);
  groove4 = new Sampler(channelBuffer34, sampleRate, 4);
  groove4.patch(out34);

  play56 = channel56.loadFileIntoBuffer("grooveLeft.wav", channelBuffer56);
  groove5 = new Sampler(channelBuffer56, sampleRate, 4);
  groove5.patch(out56);

  play56 = channel56.loadFileIntoBuffer("grooveRight.wav", channelBuffer56);
  groove6 = new Sampler(channelBuffer56, sampleRate, 4);
  groove6.patch(out56);

  play78 = channel78.loadFileIntoBuffer("grooveLeft.wav", channelBuffer78);
  groove7 = new Sampler(channelBuffer78, sampleRate, 4);
  groove7.patch(out78);
*/
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
// System test og tastatur-input
void keyPressed() {
  if (key == ' ') {
    //groove12.trigger(); // mellemrumstasten trigger en test på kanalerne 1 & 2
//    ambience12.looping = true;
//    ambience12.trigger();
    //birdOfTheMinute();
  } else if (key == '1') {
    groove1.trigger();
    println(groove1);
  } else if (key == '2') {
    groove2.trigger();
    println(groove2);
  } else if (key == '3') {
    groove3.trigger();
  } else if (key == '4') {
    groove4.trigger();
  } else if (key == '5') {
    groove5.trigger();
  } else if (key == '6') {
    groove6.trigger();
  } else if (key == '7') {
    groove7.trigger();
  }
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
// DEBUGGING-værktøjer

// denne bid kode giver en liste over mulige outputs, samt alternativ farve på de valgte outputs.
void outputDebug() {
  for (int i = 0; i < mixerInfo.length; i++) {
    println("[" + i + "]" + mixerInfo[i].getName());
    /*if (i == channelOut12  || i == channelOut34  || i == channelOut56  || i == channelOut78) {
     fill(255);
     text("[" + i + "] " + mixerInfo[i].getName(), 15, 20 + i * 25, i);
     } else {
     fill(120);
     text("[" + i + "] " + mixerInfo[i].getName(), 15, 20 + i * 25, i);
     }*/
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