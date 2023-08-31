#pragma once
#include "precomp.h"
#include "zi/utility.h"

namespace om {
namespace system {
enum class LoginResult {
  CANCELLED,
  SUCCESS,
  BAD_USERNAME_PW,
  CONNECTION_ERROR,
};

class Account : private om::SingletonBase<Account> {
 public:
  static const std::string& username() { return instance().username_; }
  static uint32_t userid() { return instance().userid_; }
  static std::string& endpoint( const std::string& path );
  static void set_endpoint(std::string endpoint);
  static uint8_t userlevel() { return instance().userlevel_; }

  static LoginResult Login(const std::string& username,
                            const std::string& password);  
  static bool IsLoggedIn();
 private:  
  Account();
  ~Account();
  std::string username_;
  uint32_t userid_;
  uint8_t userlevel_;
  std::string endpoint_;  
  friend class zi::singleton<Account>;  
};
}
}  // namespace om::system::