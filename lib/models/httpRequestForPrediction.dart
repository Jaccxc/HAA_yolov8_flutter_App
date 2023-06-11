
Future<double> requestPrediction(List<List<double>> PPGSequence) async{
  String type = "";
  if(PPGSequence.length == 3){
    type = "nir_bg";
  } else {
    type = "nir_ua";
  }
  return 2.5;
}