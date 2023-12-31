#pragma once

#include "precomp.h"

namespace om {
namespace string {

inline void downcase(std::string& str) { boost::to_lower(str); }

inline bool startsWith(const std::string& str, const std::string& prefix) {
  return boost::starts_with(str, prefix);
}

template <typename T>
static std::string num(const T& num) {
  return std::to_string(num);
}

template <typename T>
static std::string join(const T& in, const std::string sep = ", ") {
  // works on containers of strings, ints, etc.

  std::vector<std::string> tmp;
  tmp.reserve(in.size());

  for (auto& s : in) {
    tmp.push_back(boost::lexical_cast<std::string>(s));
  }

  return boost::algorithm::join(tmp, sep);
}

inline static std::vector<std::string> split(const std::string& in, char sep) {
  std::vector<std::string> result;
  size_t from = 0;
  auto to = in.find(sep);
  while (to != std::string::npos) {
    result.emplace_back(in.substr(from, to));
    from = to;
    to = in.find(sep, from);
  }

  return result;
}

template <typename T>
inline static std::string humanizeNum(const T num, const char sep = ',') {
  const std::string rawNumAsStr = om::string::num(num);

  size_t counter = 0;
  std::string ret;

  FOR_EACH_R(i, rawNumAsStr) {
    ++counter;
    ret += *i;
    if (0 == (counter % 3) && counter != rawNumAsStr.size()) {
      ret += sep;
    }
  }

  std::reverse(ret.begin(), ret.end());
  return ret;
}

template <typename T>
inline static std::string bytesToMB(const T num) {
  static const int64_t bytes_per_mb = 1048576;

  const int64_t size = static_cast<int64_t>(num) / bytes_per_mb;
  return humanizeNum(size) + "MB";
}
};
};
