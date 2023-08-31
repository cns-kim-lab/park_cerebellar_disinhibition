#include "system/account.h"
#include "system/omLocalPreferences.hpp"
#include "events/events.h"
#include "task/taskManager.h"

#include "network/sqlQuery.h"


namespace om {
namespace system {

Account::Account()
    : username_(OmLocalPreferences::getUsername().toStdString()),
      endpoint_(OmLocalPreferences::getEndpoint().toStdString()) {}
Account::~Account() {}

bool Account::IsLoggedIn() {
  return instance().userid_ > 0 && !instance().username_.empty();
}

LoginResult Account::Login(const std::string& username,
                            const std::string& password) {
  if (!task::TaskManager::AttemptFinishTask()) {
    return LoginResult::CANCELLED; 
  }
  auto rsl = network::SqlQuery::Connect(instance().endpoint_, DEFAULT_SQL_PORT, username);
  switch(rsl) {
    case om::network::SqlConnectResult::SUCCESS:
      log_debugs << "sql connection completed";
      break;
    case om::network::SqlConnectResult::CONNECTION_ERROR:
    case om::network::SqlConnectResult::INVALID_CON_INFO:
    default:    
      instance().userid_ = 0;
      instance().username_ = "";
      om::event::ConnectionChanged();
      return LoginResult::CONNECTION_ERROR;
  }
  std::string sentence = "CALL omni_login(\"" + username + "\");";
  auto rsl_ = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl_ || !rsl_->first() ) {
    instance().userid_ = 0;
    instance().username_ = "";
    om::event::ConnectionChanged();
    return LoginResult::BAD_USERNAME_PW;
  }
  instance().userid_ = rsl_->getUInt("id");
  instance().username_ = username;
  instance().userlevel_ = (uint8_t)rsl_->getUInt("level");
  om::event::ConnectionChanged();  
  return LoginResult::SUCCESS;  
}

void Account::set_endpoint(std::string endpoint) {
  instance().endpoint_ = endpoint;
}
std::string& Account::endpoint(const std::string& path) {
  instance().endpoint_ = instance().endpoint_ + path;  //no use 
  return instance().endpoint_;
}

}
}  // namespace om::system::