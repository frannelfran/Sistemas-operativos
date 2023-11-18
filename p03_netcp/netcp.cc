#include <iostream>
#include <fstream>

using namespace std;

int main(int argc, char* argv[]) {
  if (argc == 2) {
    string ayuda = argv[1];
    if(ayuda == "--help" || ayuda == "-h" ) {
      cout << "Modo de empleo: ./netcp testfile " << endl;
      exit(EXIT_SUCCESS);
    }
  }
  if (argc != 2) {
    cout << "Falta un archivo como argumento: pruebe [-h | --help] para más información" << endl;
    return 1;
  }
  // Lectura del fichero
  ifstream file(argv[1]);
  // Comprobar el tamaño del fichero y si existe
  streampos size = file.tellg();
  file.seekg(0, ios::end);
  size = file.tellg() - size; // Obtener el tamaño del fichero en bytes
  if (size > 1024 || !file.is_open()) {
    cout << "netcp: no se puede abrir " << "'" << argv[1] << "'" << ": no such file or directory" << endl;
    exit(EXIT_FAILURE);
  }
  





  return 0;
}