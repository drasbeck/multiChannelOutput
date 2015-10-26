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
//   - gøres med setGain på outArray[0] eksempelvis -- når vi har højttalerne.
// Få styr på sound scapes.
// Nice to have: Lav fadeIn, fadeOut, fadeCross.
//-------------------------------------------------------------------------------------

import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.signals.*;
import javax.sound.sampled.*;
import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;


// Blandet
Arduino arduino;
Debug debugger;
Mixer.Info[] mixerInfo;
Fugl minutFugl;
float sampleRate = 44100f;


// Output kanaler
int channelOut12, channelOut34, channelOut56, channelOut78;
boolean channelOut12Set = false, 
  channelOut34Set = false, 
  channelOut56Set = false, 
  channelOut78Set = false;

// minim stuff
Minim              minim;
MultiChannelBuffer channelBuffer;
float              buffer;
AudioOutput        outArray[] = new AudioOutput[4];


// Samplere til lyd
Sampler
  ambience12, ambience34, ambience56, ambience78, // alle
  morgenmodet12, // 1 -- done ???
  jagten12, jagten34, jagten56, jagten78, // alle -- IKKE done - mangler gallop-plask og gallop-træbro
  hundeneBelonnes34, // 4 - IKKE done - mangler lyden af hunde der æder
  ideernesVandring56, // 6 - done - hvis musikken spiller
  slottene78, // 7 -- IKKE done - skal mastereres
  ambience[] = new Sampler [4], 
  groove[] = new Sampler[7], grooveTemp, // bruges til at teste en helt anden type lyd
  fugleArray[][] = new Sampler[4][7];


// Forbrug
int morgenmodet;
int jagten;
int slottene;
int ideernesVandring;
int hundeneBelonnes;

// Ambience
int ambienceLoop, ambienceDuration;

// Cooldowns
int warmUp = 5000; // normalt 60000
boolean warmUpDone = false;

// Morgenmødet cooldown
boolean morgenmodetCooldown = true;
int morgenmodetCooldownBegin;
int morgenmodetCooldownDuration = 120000; // normalt 120000 millisekunder aka 2 minutter

// Jagten cooldown
boolean jagtenCooldown = true;
int jagtenCooldownBegin;
int jagtenCooldownDuration = 120000; // normalt 120000 millisekunder aka 2 minutter

// Slottene cooldown
boolean slotteneCooldown = true;
int slotteneCooldownBegin;
int slotteneCooldownDuration = 120000; // normalt 120000 millisekunder aka 2 minutter

// Ideernes Vandring cooldown
boolean ideernesVandringCooldown = true;
int ideernesVandringCooldownBegin;
int ideernesVandringCooldownDuration = 120000; // normalt 120000 millisekunder aka 2 minutter

// Hundene Belønnes cooldown
boolean hundeneBelonnesCooldown = true;
int hundeneBelonnesCooldownBegin;
int hundeneBelonnesCooldownDuration = 120000; // normalt 120000 millisekunder aka 2 minutter

// Intervaller
int hvertTiendeSekund, hvertMinut, hvertFemteMinut;


//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void setup()
{
  // vindue sættes op
  size(512, 800, P2D);
  //textAlign(LEFT, TOP);

  // lydkortets outputkanaler findes og aktiveres
  mixerInfo = AudioSystem.getMixerInfo();

  for (int i = 0; i < mixerInfo.length; i++) {
    //println("[" + Math.round(millis() / 1000) + "] " + mixerInfo[i].getName());
    String mixerName = mixerInfo[i].getName();
    if (mixerName.equals("Line 1/2 (M-Track Eight)") && channelOut12Set == false) {
      println("[" + Math.round(millis() / 1000) + "] Line 12 = softwareMixerOut #" + i);
      channelOut12 = i;
      channelOut12Set = true;
    }
    if (mixerName.equals("Line 3/4 (M-Track Eight)") && channelOut34Set == false) {
      println("[" + Math.round(millis() / 1000) + "] Line 34 = softwareMixerOut #" + i);
      channelOut34 = i;
      channelOut34Set = true;
    }
    if (mixerName.equals("Line 5/6 (M-Track Eight)") && channelOut56Set == false) {
      println("[" + Math.round(millis() / 1000) + "] Line 56 = softwareMixerOut #" + i);
      channelOut56 = i;
      channelOut56Set = true;
    }
    if (mixerName.equals("Line 7/8 (M-Track Eight)") && channelOut78Set == false) {
      println("[" + Math.round(millis() / 1000) + "] Line 78 = softwareMixerOut #" + i);
      channelOut78 = i;
      channelOut78Set = true;
    } else {
      //println("[" + Math.round(millis() / 1000) + "] softwareMixerOut# " + i + " skal ikke bruges i denne omgang");
    }
  }


  // random fugle-klassen klargøres
  minutFugl = new Fugl();


  // debugger sættes op
  debugger = new Debug();


  // arduinoen addreseres og serieforbindelse oprettes
  arduino = new Arduino(this, Arduino.list()[1], 57600); // [1] på JagtSkov computeren
  for (int i = 0; i <= 13; i++) {
    arduino.pinMode(i, Arduino.INPUT);
  }


  // kanalerne får en Minim og en MultiChannelBuffer til deling
  minim = new Minim(this);
  channelBuffer = new MultiChannelBuffer(1, 1024);


  // mixere sættes op med hver deres line out.
  Mixer mixer12 = AudioSystem.getMixer(mixerInfo[channelOut12]);
  minim.setOutputMixer(mixer12);
  outArray[0] = minim.getLineOut();

  Mixer mixer34 = AudioSystem.getMixer(mixerInfo[channelOut34]);
  minim.setOutputMixer(mixer34);
  outArray[1] = minim.getLineOut();

  Mixer mixer56 = AudioSystem.getMixer(mixerInfo[channelOut56]);
  minim.setOutputMixer(mixer56);
  outArray[2] = minim.getLineOut();

  Mixer mixer78 = AudioSystem.getMixer(mixerInfo[channelOut78]);
  minim.setOutputMixer(mixer78);
  outArray[3] = minim.getLineOut();


  // de forskellige debuggers
  //  debugger.arduino();
  //  debugger.output();
  //  debugger.control();


  // gem alle lyde i hukommelsen
  loadSounds();

  // startup tekst
  println("[" + Math.round(millis() / 1000) + "] multiChannelOutput");
  println("[" + Math.round(millis() / 1000) + "] build 15A282a");
  println("[" + Math.round(millis() / 1000) + "] Boottid " + millis() + " millisekunder.");
  println("[" + Math.round(millis() / 1000) + "] Varmer PIR-sensorerne op, det tager 60 sekunder.");
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void draw() {
  text("FPS: " + nfs(frameRate, 2, 1), 439, 20); // framerate, mest bare Proof of Life
  drawGui();

  // Aktivér lydbilleder via PIR-sensorer.
  if (warmUp < millis()) {
    if (!warmUpDone) {
      println("[" + Math.round(millis() / 1000) + "] PIR-sensorerne er klar.");
      warmUpDone = true;
    }

    // Morgenmødet trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(7) == Arduino.HIGH && jagtenCooldown) { //Morgenmødet startes når dPIN7 aktiveres
      morgenmodet12.trigger();

      // Cooldown mekanisme
      morgenmodetCooldown = false;
      morgenmodetCooldownBegin = millis();
      morgenmodet++;
      println("[" + Math.round(millis() / 1000) + "] Morgenmødet startet " + morgenmodet + " gang(e), klar igen om " + Math.round(morgenmodetCooldownDuration / 1000) + " sekunder.");
    }
    if (morgenmodetCooldownBegin + morgenmodetCooldownDuration < millis() && !morgenmodetCooldown) {
      morgenmodetCooldown = true;
      println("[" + Math.round(millis() / 1000) + "] Morgenmødet klar.");
    }

    // Jagten trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(8) == Arduino.HIGH && morgenmodetCooldown) { // Jagten startes når dPIN7 aktiveres
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
      println("[" + Math.round(millis() / 1000) + "] Jagten klar.");
    }

    // Hundene Belønnes trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(7) == Arduino.HIGH && hundeneBelonnesCooldown) { //hundeneBelonnes startes når dPIN7 aktiveres
      /*    
       hundeneBelonnes34.trigger();
       */

      // Cooldown mekanisme
      hundeneBelonnesCooldown = false;
      hundeneBelonnesCooldownBegin = millis();
      hundeneBelonnes++;
      println("[" + Math.round(millis() / 1000) + "] Hundene Belønnes startet " + hundeneBelonnes + " gang(e), klar igen om " + Math.round(hundeneBelonnesCooldownDuration / 1000) + " sekunder.");
    }
    if (hundeneBelonnesCooldownBegin + hundeneBelonnesCooldownDuration < millis() && !hundeneBelonnesCooldown) {
      hundeneBelonnesCooldown = true;
      println("[" + Math.round(millis() / 1000) + "] Hundene Belønnes klar.");
    }

    // Ideernes Vandring trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(7) == Arduino.HIGH && ideernesVandringCooldown) { //ideernesVandring startes når dPIN7 aktiveres
      ideernesVandring56.trigger();

      // Cooldown mekanisme
      ideernesVandringCooldown = false;
      ideernesVandringCooldownBegin = millis();
      ideernesVandring++;
      println("[" + Math.round(millis() / 1000) + "] Ideernes Vandring startet " + ideernesVandring + " gang(e), klar igen om " + Math.round(ideernesVandringCooldownDuration / 1000) + " sekunder.");
    }
    if (ideernesVandringCooldownBegin + ideernesVandringCooldownDuration < millis() && !ideernesVandringCooldown) {
      ideernesVandringCooldown = true;
      println("[" + Math.round(millis() / 1000) + "] Ideernes Vandring klar.");
    }

    // Slottene trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(11) == Arduino.HIGH && slotteneCooldown) { //Slottene startes når dPIN7 aktiveres
      //slottene78.trigger();

      // Cooldown mekanisme
      slotteneCooldown = false;
      slotteneCooldownBegin = millis();
      slottene++;
      println("[" + Math.round(millis() / 1000) + "] Slottene startet " + slottene + " gang(e), klar igen om " + Math.round(slotteneCooldownDuration / 1000) + " sekunder.");
    }
    if (slotteneCooldownBegin + slotteneCooldownDuration < millis() && !slotteneCooldown) {
      slotteneCooldown = true;
      println("[" + Math.round(millis() / 1000) + "] Slottene klar.");
    }
  }

  // Intervaller
  if (millis() > hvertTiendeSekund + 9999) {
    hvertTiendeSekund = millis();
  }

  if (millis() > hvertMinut + 59999) {
    hvertMinut = millis();
    for (int i = 0; i < ambience.length; i++) {
      ambience[i].trigger();
    }
    minutFugl.play();
  }

  if (millis() > hvertFemteMinut + 299999) {
    hvertTiendeSekund = millis();
  }
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void loadSounds() {
  buffer = minim.loadFileIntoBuffer("04 No. 1 Menuetto - trio.wav", channelBuffer);
  ideernesVandring56 = new Sampler(channelBuffer, sampleRate, 1);
  ideernesVandring56.patch(outArray[2]);

  for (int i = 0; i < ambience.length; i++) {
    int nu = millis();

    buffer = minim.loadFileIntoBuffer("0. Ambience12.wav", channelBuffer);
    ambience[i] = new Sampler(channelBuffer, sampleRate, 1);
    ambience[i].patch(outArray[i]);

    print("[" + Math.round(millis() / 1000) + "] ambience til udgang " );    
    if (i == 0) {
      print("12");
    } else if (i == 1) {
      print("34");
    } else if (i == 2) {
      print("56");
    } else if (i == 3) {
      print("78");
    }
    println(" tog " + (millis() - nu) + " millisekunder at loade");
  }

  /*
  buffer = minim.loadFileIntoBuffer("morgenmodet12.mp3", channelBuffer);
   morgenmodet12 = new Sampler(channelBuffer, sampleRate, 1);
   morgenmodet12.patch(outArray[0]);
   */

  /*
  buffer = minim.loadFileIntoBuffer("Sanktus.wav", channelBuffer);
   ideernesVandring56 = new Sampler(channelBuffer, sampleRate, 1);
   ideernesVandring56.patch(outArray[2]);
   */

  /*
  buffer = minim.loadFileIntoBuffer("jagten12.mp3", channelBuffer);
   jagten12 = new Sampler(channelBuffer, sampleRate, 1);
   jagten12.patch(outArray[0]);
   
   buffer = minim.loadFileIntoBuffer("jagten34.mp3", channelBuffer);
   jagten34 = new Sampler(channelBuffer, sampleRate, 1);
   jagten34.patch(outArray[1]);
   
   buffer = minim.loadFileIntoBuffer("jagten56.mp3", channelBuffer);
   jagten56 = new Sampler(channelBuffer, sampleRate, 1);
   jagten56.patch(outArray[2]);
   
   buffer = minim.loadFileIntoBuffer("jagten78.mp3", channelBuffer);
   jagten78 = new Sampler(channelBuffer, sampleRate, 1);
   jagten78.patch(outArray[3]);
   */

  // lyde til test af kanaler
  for (int i = 0; i < groove.length; i++) {
    int nu = millis();
    print("[" + Math.round(millis() / 1000) + "] ");
    if (i % 2 == 0) {
      buffer = minim.loadFileIntoBuffer("grooveLeft.wav", channelBuffer);
      print("grooveLeft.wav til venstre kanal i udgang ");
    } else {
      buffer = minim.loadFileIntoBuffer("grooveRight.mp3", channelBuffer);
      print("grooveRight.mp3 til højre kanal i udgang ");
    }
    grooveTemp = new Sampler(channelBuffer, sampleRate, 4);

    if (i == 0 || i == 1) {
      grooveTemp.patch(outArray[0]);
      print("12");
    } else if (i == 2 || i == 3) {
      grooveTemp.patch(outArray[1]);
      print("34");
    } else if (i == 4 || i == 5) {
      grooveTemp.patch(outArray[2]);
      print("56");
    } else if (i == 6) {
      grooveTemp.patch(outArray[3]);
      print("78");
    }
    groove[i] = grooveTemp;
    println(" tog " + (millis() - nu) + " millisekunder at loade");
  }

  // alle de vilkårlige fugle
  minutFugl.load();
  println("=======================");
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
// System test og tastatur-input
void keyPressed() {
  if (key == ' ') {
    //minutFugl.play(); // spil en vilkårlig minut fugl
    ideernesVandring56.trigger();
  } else if (key == '1') {
    groove[0].trigger(); // test kanal 1
  } else if (key == '2') {
    groove[1].trigger(); // test kanal 2
  } else if (key == '3') {
    groove[2].trigger(); // test kanal 3
  } else if (key == '4') {
    groove[3].trigger(); // test kanal 4
  } else if (key == '5') {
    groove[4].trigger(); // test kanal 5
  } else if (key == '6') {
    groove[5].trigger(); // test kanal 6
  } else if (key == '7') {
    groove[6].trigger(); // test kanal 7
  } else if (key == '8') {
  } else if (key == '9') {
  } else if (key == '0') {
  }
}




void drawGui() {
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
  for (int i = 0; i < outArray[0].bufferSize() - 1; i++) {
    float x1 = map(i, 0, outArray[0].bufferSize(), 0, width);
    float x2 = map(i + 1, 0, outArray[0].bufferSize(), 0, width);
    line(x1, 50 + outArray[0].left.get(i) * 50, x2, 50 + outArray[0].left.get(i + 1) * 50);
    line(x1, 150 + outArray[0].right.get(i) * 50, x2, 150 + outArray[0].right.get(i + 1) * 50);
  }
  rect(0, 0, outArray[0].left.level() * width, 100);
  rect(0, 100, outArray[0].right.level() * width, 100);

  for (int i = 0; i < outArray[1].bufferSize() - 1; i++) {
    float x1 = map(i, 0, outArray[1].bufferSize(), 0, width);
    float x2 = map(i+1, 0, outArray[1].bufferSize(), 0, width);
    line(x1, 250 + outArray[1].left.get(i) * 50, x2, 250 + outArray[1].left.get(i + 1) * 50);
    line(x1, 350 + outArray[1].right.get(i) * 50, x2, 350 + outArray[1].right.get(i + 1) * 50);
  }
  rect(0, 200, outArray[1].left.level() * width, 100);
  rect(0, 300, outArray[1].right.level() * width, 100);

  for (int i = 0; i < outArray[2].bufferSize() - 1; i++) {
    float x1 = map(i, 0, outArray[2].bufferSize(), 0, width);
    float x2 = map(i + 1, 0, outArray[2].bufferSize(), 0, width);
    line(x1, 450 + outArray[2].left.get(i) * 50, x2, 450 + outArray[2].left.get(i + 1) * 50);
    line(x1, 550 + outArray[2].right.get(i) * 50, x2, 550 + outArray[2].right.get(i + 1) * 50);
  }
  rect(0, 400, outArray[2].left.level() * width, 100);
  rect(0, 500, outArray[2].right.level() * width, 100);

  for (int i = 0; i < outArray[3].bufferSize() - 1; i++) {
    float x1 = map(i, 0, outArray[3].bufferSize(), 0, width);
    float x2 = map(i + 1, 0, outArray[3].bufferSize(), 0, width);
    line(x1, 650 + outArray[3].left.get(i) * 50, x2, 650 + outArray[3].left.get(i + 1) * 50);
  }
  rect(0, 600, outArray[3].left.level() * width, 100);

  // On screen output nummerering
  for (int i = 0; i < 7; i++) {
    text("Output #" + (i + 1), 440, ((i + 1) * 100) - 60);
  }
}