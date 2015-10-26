class Debug {
  // CONSTRUCTOR
  Debug () {
    return;
  }

  // FUNCTIONS
  // denne bid kode giver en liste over mulige outputs, samt alternativ farve på de valgte outputs.
  void output() {
    for (int i = 0; i < mixerInfo.length; i++) {
      println("[" + i + "]" + mixerInfo[i].getName());

      // uncomment hvis det skal deles med sketchens skærm
/*
      if (i == channelOut12  || i == channelOut34  || i == channelOut56  || i == channelOut78) {
        fill(255);
        text("[" + i + "] " + mixerInfo[i].getName(), 15, 20 + i * 25, i);
      } else {
        fill(120);
        text("[" + i + "] " + mixerInfo[i].getName(), 15, 20 + i * 25, i);
      }
*/
    }
  }





  // -||- liste over hvilke former for kontrol minim har over output.
  void control() {
    if (out[0].hasControl(Controller.PAN)) {
      print("DEBUG: pan control        : out[0] ja  |");
    } else {
      print("DEBUG: pan control        : out[0] nej |");
    }
    if (out[1].hasControl(Controller.PAN)) {
      print(" out[1] ja  |");
    } else {
      print(" out[1] nej |");
    }
    if (out[2].hasControl(Controller.PAN)) {
      print(" out[2] ja  |");
    } else {
      print(" out[2] nej |");
    }
    if (out[3].hasControl(Controller.PAN)) {
      println(" out[3] ja");
    } else {
      println(" out[3] nej");
    }

    if (out[0].hasControl(Controller.VOLUME)) {
      print("DEBUG: volume control     : out[0] ja  |");
    } else {
      print("DEBUG: volume control     : out[0] nej |");
    }
    if (out[1].hasControl(Controller.VOLUME)) {
      print(" out[1] ja  |");
    } else {
      print(" out[1] nej |");
    }
    if (out[2].hasControl(Controller.VOLUME)) {
      print(" out[2] ja  |");
    } else {
      print(" out[2] nej |");
    }
    if (out[3].hasControl(Controller.VOLUME)) {
      println(" out[3] ja");
    } else {
      println(" out[3] nej");
    }

    if (out[0].hasControl(Controller.SAMPLE_RATE)) {
      print("DEBUG: sample rate control: out[0] ja  |");
    } else {
      print("DEBUG: sample rate control: out[0] nej |");
    }
    if (out[1].hasControl(Controller.SAMPLE_RATE)) {
      print(" out[1] ja  |");
    } else {
      print(" out[1] nej |");
    }
    if (out[2].hasControl(Controller.SAMPLE_RATE)) {
      print(" out[2] ja  |");
    } else {
      print(" out[2] nej |");
    }
    if (out[3].hasControl(Controller.SAMPLE_RATE)) {
      println(" out[3] ja");
    } else {
      println(" out[3] nej");
    }

    if (out[0].hasControl(Controller.BALANCE)) {
      print("DEBUG: balance control    : out[0] ja  |");
    } else {
      print("DEBUG: balance control    : out[0] nej |");
    }
    if (out[1].hasControl(Controller.BALANCE)) {
      print(" out[1] ja  |");
    } else {
      print(" out[1] nej |");
    }
    if (out[2].hasControl(Controller.BALANCE)) {
      print(" out[2] ja  |");
    } else {
      println(" out[2] nej |");
    }
    if (out[3].hasControl(Controller.BALANCE)) {
      println(" out[3] ja");
    } else {
      println(" out[3] nej");
    }

    if (out[0].hasControl(Controller.MUTE)) {
      print("DEBUG: mute control       : out[0] ja  |");
    } else {
      print("DEBUG: mute control       : out[0] nej |");
    }
    if (out[1].hasControl(Controller.MUTE)) {
      print(" out[1] ja  |");
    } else {
      print(" out[1] nej |");
    }
    if (out[2].hasControl(Controller.MUTE)) {
      print(" out[2] ja  |");
    } else {
      print(" out[2] nej |");
    }
    if (out[3].hasControl(Controller.MUTE)) {
      println(" out[3] ja");
    } else {
      println(" out[3] nej");
    }

    if (out[0].hasControl(Controller.GAIN)) {
      print("DEBUG: gain control       : out[0] ja  |");
    } else {
      print("DEBUG: gain control       : out[0] nej |");
    }

    if (out[1].hasControl(Controller.GAIN)) {
      print(" out[1] ja  |");
    } else {
      print(" out[1] nej |");
    }

    if (out[2].hasControl(Controller.GAIN)) {
      print(" out[2] ja  |");
    } else {
      print(" out[2] nej |");
    }

    if (out[3].hasControl(Controller.GAIN)) {
      println(" out[3] ja");
    } else {
      println(" out[3] nej");
    }
  }





  // -||- liste over tilgængelige seriel-forbindelser
  void arduino() {
    print("DEBUG: Array over arduino-forbindelser: ");
    println(Arduino.list());
  }
}