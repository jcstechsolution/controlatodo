# Google ML Kit Text Recognition (google_mlkit_text_recognition) incluye,
# como código de la librería, referencias opcionales a reconocedores de
# otros alfabetos (chino, japonés, coreano, devanagari) que esta app NO usa
# ni incluye como dependencia (solo se usa el reconocedor de texto latino).
# R8 falla al no encontrar esas clases durante la minificación del build de
# release; como nunca se llaman en tiempo de ejecución, se le indica a R8
# que las ignore en vez de fallar.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
