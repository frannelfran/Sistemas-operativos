#include <iostream>

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
    cout << "Pruebe ‘TM_simulator [-h | --help]’ para más información." << endl;
    return 1;
  }
  
  








  return 0;
}