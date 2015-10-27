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
//   - gøres med setGain på out[0] eksempelvis -- når vi har højttalerne.
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
AudioOutput        out[] = new AudioOutput[4];


// Samplere til lyd
Sampler
  ambience12, ambience34, ambience56, ambience78, // alle
  morgenmodet12, // 1
  jagten12, jagten34, jagten56, jagten78, // alle
  hundeneBelonnes34, // 4
  ideernesVandring56, // 6
  slottene78, // 7
  ambience[] = new Sampler [4], 
  groove[] = new Sampler[7], grooveTemp, // bruges til at teste en helt anden type lyd
  fugle[][] = new Sampler[4][7];


// Forbrug
int morgenmodet;
int jagten;
int slottene;
int ideernesVandring;
int hundeneBelonnes;

// Ambience
int ambienceLoop, ambienceDuration;

// Cooldowns
int warmUp = 60000; // normalt 01 mike = 60000
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
  size(256, 176, P2D);
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
  out[0] = minim.getLineOut();

  Mixer mixer34 = AudioSystem.getMixer(mixerInfo[channelOut34]);
  minim.setOutputMixer(mixer34);
  out[1] = minim.getLineOut();

  Mixer mixer56 = AudioSystem.getMixer(mixerInfo[channelOut56]);
  minim.setOutputMixer(mixer56);
  out[2] = minim.getLineOut();

  Mixer mixer78 = AudioSystem.getMixer(mixerInfo[channelOut78]);
  minim.setOutputMixer(mixer78);
  out[3] = minim.getLineOut();


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


  // starter ambience
  for (int i = 0; i < ambience.length; i++) {
    ambience[i].trigger();
  }
  println("[" + Math.round(millis() / 1000) + "] Ambience startet.");
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void draw() {
  drawGui();
  pirTrigger();

  // Intervaller
  if (millis() > hvertTiendeSekund + 9999) {
    hvertTiendeSekund = millis();
  }

  if (millis() > hvertMinut + 59999) {
    hvertMinut = millis();
    minutFugl.play();
  }

  if (millis() > hvertFemteMinut + 299999) {
    hvertFemteMinut = millis();
    for (int i = 0; i < ambience.length; i++) {
      ambience[i].trigger();
    }
    println("[" + Math.round(millis() / 1000) + "] Ambience starter forfra.");
  }
}










//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
void loadSounds() {
  int nu;

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Ideernes Vandring til udgang 5" );
  buffer = minim.loadFileIntoBuffer("04 No. 1 Menuetto - trio.wav", channelBuffer);
  ideernesVandring56 = new Sampler(channelBuffer, sampleRate, 1);
  ideernesVandring56.patch(out[2]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Morgenmødet til udgang 1" );
  buffer = minim.loadFileIntoBuffer("1. Morgenmodet.wav", channelBuffer);
  morgenmodet12 = new Sampler(channelBuffer, sampleRate, 1);
  morgenmodet12.patch(out[0]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");


  /*
  buffer = minim.loadFileIntoBuffer("Sanktus.wav", channelBuffer);
   ideernesVandring56 = new Sampler(channelBuffer, sampleRate, 1);
   ideernesVandring56.patch(out[2]);
   */

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Jagten til udgang 12" );
  buffer = minim.loadFileIntoBuffer("2. Jagten12.wav", channelBuffer);
  jagten12 = new Sampler(channelBuffer, sampleRate, 1);
  jagten12.patch(out[0]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Jagten til udgang 34" );
  buffer = minim.loadFileIntoBuffer("2. Jagten34.wav", channelBuffer);
  jagten34 = new Sampler(channelBuffer, sampleRate, 1);
  jagten34.patch(out[1]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Jagten til udgang 56" );
  buffer = minim.loadFileIntoBuffer("2. Jagten56.wav", channelBuffer);
  jagten56 = new Sampler(channelBuffer, sampleRate, 1);
  jagten56.patch(out[2]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Jagten til udgang 78" );
  buffer = minim.loadFileIntoBuffer("2. Jagten78.wav", channelBuffer);
  jagten78 = new Sampler(channelBuffer, sampleRate, 1);
  jagten78.patch(out[3]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");

  nu = millis();
  print("[" + Math.round(millis() / 1000) + "] Slottene til udgang 7" );
  buffer = minim.loadFileIntoBuffer("7. Slottene.wav", channelBuffer);
  slottene78 = new Sampler(channelBuffer, sampleRate, 1);
  slottene78.patch(out[3]);
  println(" tog " + (millis() - nu) + " millisekunder at loade.");

  // load ambience
  for (int i = 0; i < ambience.length; i++) {
    nu = millis();

    buffer = minim.loadFileIntoBuffer("0. Ambience12.wav", channelBuffer);
    ambience[i] = new Sampler(channelBuffer, sampleRate, 1);
    ambience[i].patch(out[i]);

    print("[" + Math.round(millis() / 1000) + "] Ambience til udgang " );    
    if (i == 0) {
      print("12");
    } else if (i == 1) {
      print("34");
    } else if (i == 2) {
      print("56");
    } else if (i == 3) {
      print("78");
    }
    println(" tog " + (millis() - nu) + " millisekunder at loade.");
  }

  // lyde til test af kanaler
  for (int i = 0; i < groove.length; i++) {
    nu = millis();
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
      grooveTemp.patch(out[0]);
      print("12");
    } else if (i == 2 || i == 3) {
      grooveTemp.patch(out[1]);
      print("34");
    } else if (i == 4 || i == 5) {
      grooveTemp.patch(out[2]);
      print("56");
    } else if (i == 6) {
      grooveTemp.patch(out[3]);
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
// Aktivér lydbilleder via PIR-sensorer.
void pirTrigger () {
  if (warmUp < millis()) {
    if (!warmUpDone) {
      println("[" + Math.round(millis() / 1000) + "] PIR-sensorerne er klar.");
      warmUpDone = true;
    }

    // Morgenmødet trigger- og cooldown-funktionalitet
    if (arduino.digitalRead(7) == Arduino.HIGH && morgenmodetCooldown) { //Morgenmødet startes når dPIN7 aktiveres
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
    if (arduino.digitalRead(8) == Arduino.HIGH && jagtenCooldown) { // Jagten startes når dPIN8 aktiveres

      jagten12.trigger();
      jagten34.trigger();
      jagten56.trigger();
      jagten78.trigger();


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
    if (arduino.digitalRead(7) == Arduino.HIGH && hundeneBelonnesCooldown) { //hundeneBelonnes startes når dPIN9 aktiveres
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
    if (arduino.digitalRead(10) == Arduino.HIGH && ideernesVandringCooldown) { //ideernesVandring startes når dPIN10 aktiveres
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
    if (arduino.digitalRead(11) == Arduino.HIGH && slotteneCooldown) { //Slottene startes når dPIN11 aktiveres
      slottene78.trigger();

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

  /*
  // On screen Arduino debugging
   for (int i = 7; i <= 11; i++) {
   if (arduino.digitalRead(i) == Arduino.HIGH) {
   fill(243, 552, 117);
   } else {
   fill(84, 145, 158);
   }
   rect(420 - i * 30, 360, 30, 30);
   text((char)i - 6, 420 - i * 30, 360);
   }
   */

  text("FPS: " + nfs(frameRate, 2, 1), 180, 18); // framerate, mest bare Proof of Life


  fill(255, 128);
  rect(0, 2, out[0].left.level() * width, 21);
  rect(0, 27, out[0].right.level() * width, 21);
  rect(0, 52, out[1].left.level() * width, 21);
  rect(0, 77, out[1].right.level() * width, 21);
  rect(0, 102, out[2].left.level() * width, 21);
  rect(0, 127, out[2].right.level() * width, 21);
  rect(0, 152, out[3].left.level() * width, 21);
}