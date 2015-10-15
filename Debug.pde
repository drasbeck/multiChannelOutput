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
    if (outArray[0].hasControl(Controller.PAN)) {
      print("DEBUG: pan control        : outArray[0] ja  |");
    } else {
      print("DEBUG: pan control        : outArray[0] nej |");
    }
    if (outArray[1].hasControl(Controller.PAN)) {
      print(" outArray[1] ja  |");
    } else {
      print(" outArray[1] nej |");
    }
    if (outArray[2].hasControl(Controller.PAN)) {
      print(" outArray[2] ja  |");
    } else {
      print(" outArray[2] nej |");
    }
    if (outArray[3].hasControl(Controller.PAN)) {
      println(" outArray[3] ja");
    } else {
      println(" outArray[3] nej");
    }

    if (outArray[0].hasControl(Controller.VOLUME)) {
      print("DEBUG: volume control     : outArray[0] ja  |");
    } else {
      print("DEBUG: volume control     : outArray[0] nej |");
    }
    if (outArray[1].hasControl(Controller.VOLUME)) {
      print(" outArray[1] ja  |");
    } else {
      print(" outArray[1] nej |");
    }
    if (outArray[2].hasControl(Controller.VOLUME)) {
      print(" outArray[2] ja  |");
    } else {
      print(" outArray[2] nej |");
    }
    if (outArray[3].hasControl(Controller.VOLUME)) {
      println(" outArray[3] ja");
    } else {
      println(" outArray[3] nej");
    }

    if (outArray[0].hasControl(Controller.SAMPLE_RATE)) {
      print("DEBUG: sample rate control: outArray[0] ja  |");
    } else {
      print("DEBUG: sample rate control: outArray[0] nej |");
    }
    if (outArray[1].hasControl(Controller.SAMPLE_RATE)) {
      print(" outArray[1] ja  |");
    } else {
      print(" outArray[1] nej |");
    }
    if (outArray[2].hasControl(Controller.SAMPLE_RATE)) {
      print(" outArray[2] ja  |");
    } else {
      print(" outArray[2] nej |");
    }
    if (outArray[3].hasControl(Controller.SAMPLE_RATE)) {
      println(" outArray[3] ja");
    } else {
      println(" outArray[3] nej");
    }

    if (outArray[0].hasControl(Controller.BALANCE)) {
      print("DEBUG: balance control    : outArray[0] ja  |");
    } else {
      print("DEBUG: balance control    : outArray[0] nej |");
    }
    if (outArray[1].hasControl(Controller.BALANCE)) {
      print(" outArray[1] ja  |");
    } else {
      print(" outArray[1] nej |");
    }
    if (outArray[2].hasControl(Controller.BALANCE)) {
      print(" outArray[2] ja  |");
    } else {
      println(" outArray[2] nej |");
    }
    if (outArray[3].hasControl(Controller.BALANCE)) {
      println(" outArray[3] ja");
    } else {
      println(" outArray[3] nej");
    }

    if (outArray[0].hasControl(Controller.MUTE)) {
      print("DEBUG: mute control       : outArray[0] ja  |");
    } else {
      print("DEBUG: mute control       : outArray[0] nej |");
    }
    if (outArray[1].hasControl(Controller.MUTE)) {
      print(" outArray[1] ja  |");
    } else {
      print(" outArray[1] nej |");
    }
    if (outArray[2].hasControl(Controller.MUTE)) {
      print(" outArray[2] ja  |");
    } else {
      print(" outArray[2] nej |");
    }
    if (outArray[3].hasControl(Controller.MUTE)) {
      println(" outArray[3] ja");
    } else {
      println(" outArray[3] nej");
    }

    if (outArray[0].hasControl(Controller.GAIN)) {
      print("DEBUG: gain control       : outArray[0] ja  |");
    } else {
      print("DEBUG: gain control       : outArray[0] nej |");
    }

    if (outArray[1].hasControl(Controller.GAIN)) {
      print(" outArray[1] ja  |");
    } else {
      print(" outArray[1] nej |");
    }

    if (outArray[2].hasControl(Controller.GAIN)) {
      print(" outArray[2] ja  |");
    } else {
      print(" outArray[2] nej |");
    }

    if (outArray[3].hasControl(Controller.GAIN)) {
      println(" outArray[3] ja");
    } else {
      println(" outArray[3] nej");
    }
  }





  // -||- liste over tilgængelige seriel-forbindelser
  void arduino() {
    print("DEBUG: Array over arduino-forbindelser: ");
    println(Arduino.list());
  }
}