import "package:auxiliary/auxiliary.dart";

const int numberOfWorlds = 43;

void main() {
  dartSetupLogging("main");
  String greetees = "{0, plural, one {world} other {worlds}}";
  String pattern = "Hello, {0} $greetees!";
  log.info(format(pattern, [numberOfWorlds]));
}
