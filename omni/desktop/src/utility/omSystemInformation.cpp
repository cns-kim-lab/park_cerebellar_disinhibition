#include "utility/omSystemInformation.h"

unsigned int OmSystemInformation::get_num_cores() {
  return zi::system::cpu_count;
}

unsigned int OmSystemInformation::get_total_system_memory_megs() {
  return zi::system::memory::total_mb();
}
