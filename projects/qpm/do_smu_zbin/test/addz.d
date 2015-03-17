import std.stdio;

void main() {
  auto inff = File("test.dat");
  auto outff = File("testz.dat","w");
  scope(exit) {inff.close(); outff.close();}
  foreach (line; inff.byLine()) {
    outff.write(line);
    outff.writeln(" 0.10000");
  }
}
  
