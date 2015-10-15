class Fugl {
  // global variables
  int nummer, kanal;
  String fil;

  // constructor
  Fugl (int _nummer, int _kanal) {
    nummer = _nummer;
    kanal = _kanal;

    return;
  }

  // functions
  void play() {
    fugl11.trigger();
  }

  void load() {
    int nu = millis();

    for (int fugle = 1; fugle <= 4; fugle++) {
      // filnavnet tildeles
      for (int kanaler = 1; kanaler <= 7; kanaler++) {
        print(fugle + " " + kanaler + " ");
        if (kanaler % 2 == 0) {
          fil = "fugl0" + Integer.toString(fugle) + "Right.wav";
          print(fil);
        } else {
          fil = "fugl0" + Integer.toString(fugle) + "Left.wav";
          print(fil);
        }

        // kanalen konverteres til lydkortets setup
        int kanalToStr = kanal;
        if (kanaler % 2 == 0) {
          kanalToStr = Integer.parseInt(Integer.toString(kanaler - 1) + Integer.toString(kanaler));
          print(" til højre kanal i udgang " + kanalToStr);
        } else {
          kanalToStr = Integer.parseInt(Integer.toString(kanaler) + Integer.toString(kanaler + 1));
          print(" til venstre kanal i udgang " + kanalToStr);
        }

        play12 = channel12.loadFileIntoBuffer(fil, channelBuffer12);
        fugl11 = new Sampler(channelBuffer12, sampleRate, 1);
        fugl11.patch(out12);
        println(" tog " + (millis() - nu) + " millisekunder at loade");
      }
    }
    // fuglen loades i forhold til hvilken kanal den skal spilles fra.
  }
}