// Tapasco is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Tapasco is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Tapasco.  If not, see <http://www.gnu.org/licenses/>.
//
#include <array>
#include <iostream>
#include <tapasco.hpp>

#define SZ 256
#define RUNS 25

typedef int32_t element_type;
constexpr int PE_ID = 9;

static void init_array(std::array<element_type, SZ> &arr) {
  for (size_t i = 0; i < arr.size(); ++i)
    arr[i] = (element_type)i;
}

static int arraycheck(std::array<element_type, SZ> &arr) {
  int errs = 0;
  for (size_t i = 0; i < arr.size(); i++) {
    if (arr[i] != ((element_type)i) + 42) {
      std::cerr << "ERROR: Value at " << i << " is " << arr[i] << std::endl;
      ++errs;
    }
  }
  return errs;
}

int main(int argc, char **argv) {
  // initialize TaPaSCo
  tapasco::Tapasco tapasco;

  uint64_t errs = 0;

  // check arrayupdate instance count
  uint64_t instances = tapasco_device_kernel_pe_count(tapasco.device(), PE_ID);
  std::cout << "Got " << instances << " arrayupdate instances.";
  if (!instances) {
    std::cout << "Need at least one arrayupdate instance to run.";
    exit(1);
  }

  for (int run = 0; run < RUNS; ++run) {
    // Generate array for arrayupdate output
    std::array<element_type, SZ> input;
    init_array(input);

    // Wrap the array to be TaPaSCo compatible
    auto input_buffer_pointer = tapasco::makeWrappedPointer(
        input.data(), input.size() * sizeof(element_type));

    // Launch the job
    // Arrayupdate takes only one parameter: The location of the array. It will
    // always update 256 Int`s.
    auto job = tapasco.launch(PE_ID, input_buffer_pointer);

    // Wait for job completion. Will block execution until the job is done.
    job();

    int iter_errs = arraycheck(input);
    errs += iter_errs;
    if (!iter_errs) {
      std::cout << "RUN " << run << "OK" << std::endl;
    } else {
      std::cerr << "RUN" << run << " FAILED" << std::endl;
    }
  }

  if (!errs)
    std::cout << "Arrayupdate finished without errors." << std::endl;
  else
    std::cerr << "Arrayupdate finished wit errors." << std::endl;

  return errs;
}
