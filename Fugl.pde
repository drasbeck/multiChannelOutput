class Fugl {
  // global variables
  int nummer, kanal, kanalToStr;
  String fil;
  Sampler fuglTemp;

  // en fugl bliver afspillet på baggrund af #fugl og #kanal
  void play(int _nummer, int _kanal) {
    int fugl = _nummer;
    int kanal = _kanal;

    fugle[fugl - 1][kanal - 1].trigger();
  }

  // en fugl bliver afspillet på baggrund af randomiseret fugl og kanal
  void play() {
    int fugl = (int)Math.ceil(Math.random() * 4);
    int kanal = (int)Math.ceil(Math.random() * 7);
    print("[" + Math.round(millis() / 1000) + "] ");
    println("Afspiller fugl #" + fugl + ", i kanal #" + kanal + ".");

    fugle[fugl - 1][kanal - 1].trigger();
  }

  // fuglene bliver gjort klar til brug
  void load() {
    for (int f = 1; f <= 4; f++) { // f som i fugl
      // filnavnet tildeles
      for (int kanaler = 1; kanaler <= 7; kanaler++) {
        int nu = millis();
        print("[" + Math.round(millis() / 1000) + "] ");

        if (kanaler % 2 == 0) {
          fil = "fugl0" + Integer.toString(f) + "Right.mp3";
          print(fil);
        } else {
          fil = "fugl0" + Integer.toString(f) + "Left.wav";
          print(fil);
        }

        // kanalen konverteres til lydkortets setup
        kanalToStr = kanaler;
        if (kanaler % 2 == 0) {
          kanalToStr = Integer.parseInt(Integer.toString(kanaler - 1) + Integer.toString(kanaler));
          print(" til højre kanal i udgang " + kanalToStr);
        } else {
          kanalToStr = Integer.parseInt(Integer.toString(kanaler) + Integer.toString(kanaler + 1));
          print(" til venstre kanal i udgang " + kanalToStr);
        }

        buffer = minim.loadFileIntoBuffer(fil, channelBuffer);
        fuglTemp = new Sampler(channelBuffer, sampleRate, 1);
        switch(kanalToStr) {
        case 12:
          fuglTemp.patch(out[0]);
          break;
        case 34: 
          fuglTemp.patch(out[1]);
          break;
        case 56: 
          fuglTemp.patch(out[2]);
          break;
        case 78: 
          fuglTemp.patch(out[3]);
          break;
        }
        fugle[f - 1][kanaler - 1] = fuglTemp;
        println(" tog " + (millis() - nu) + " millisekunder at loade");
      }
    }
  }
}