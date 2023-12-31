#pragma once

#include "pipeline/stage.hpp"
#include "b64/encode.h"

namespace om {
namespace pipeline {

class encode : public stage {
 public:
  template <typename T> data_var operator()(const Data<T>& in) const {
    return doEncode(reinterpret_cast<const char*>(in.data.get()),
                    in.size * sizeof(T));
  }

  data_var operator()(const Data<char>& in) const {
    return doEncode(in.data.get(), in.size);
  }

 private:
  data_var doEncode(const char* in, int64_t size) const {
    base64::encoder e;

    Data<char> out(2 * size);

    char* dest = out.data.get();

    int written = e.encode(in, size, dest);
    written += e.encode_end(&dest[written]);

    out.size = written;

    return out;
  }
};
}
}
