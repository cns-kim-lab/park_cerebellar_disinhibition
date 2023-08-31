#include "network/sqlQuery.h"
#include "common/logging.h"

namespace om {
namespace network {

SqlQuery::SqlQuery()
: host("kimserver101"), port(DEFAULT_SQL_PORT), sql_drv(nullptr), sql_con(nullptr), sql_stmt(nullptr), sql_qrsl(nullptr) {}

SqlQuery::~SqlQuery() {
    sql_con.release();
    sql_stmt.release();
}

SqlConnectResult SqlQuery::Connect(std::string address_, uint32_t port_, std::string username_) {
    if( address_.empty() || port_ < 1 || username_.empty() ) {
        log_errors << "invalid host info: " << address_ << ":" << port_ << ", user: " << username_;
        return SqlConnectResult::INVALID_CON_INFO;
    }
    log_infos << "change host: " << instance().host << ":" << instance().port << " to " << address_ << ":" << port_;
    instance().host = address_;
    instance().port = port_;
    std::string conn_link = "tcp://" + instance().host + ":" + std::to_string(instance().port);
    try {
        instance().sql_drv = get_driver_instance();
        instance().sql_con.reset( instance().sql_drv->connect(conn_link, "omnidev", "rhdxhd!Q2W") );
        //instance().sql_con.reset( instance().sql_drv->connect(conn_link, "root", "1234") );
        //instance().sql_con.reset( instance().sql_drv->connect(conn_link, "root", "rhdxhd!Q2W") );
        
        if( instance().host.compare("kimserver103") == 0 )  //181211 for tutorial mode
            instance().sql_con->setSchema("omni_" + username_);
        else
            instance().sql_con->setSchema("omni");
    } catch(sql::SQLException &e) {
        log_errors << "SQLException : " << e.what() << "(code:" << e.getErrorCode() << ")";
        return SqlConnectResult::CONNECTION_ERROR;
    }
    return SqlConnectResult::SUCCESS;
}

bool SqlQuery::Execute(std::string sentence) {
    instance().sql_qrsl.reset();
    try {
        instance().sql_stmt.reset( instance().sql_con->createStatement() );
        instance().sql_stmt->execute(sentence);
    }
    catch(sql::SQLException& e) {
        log_errors << "SQLException : " << e.what() << "(code:" << e.getErrorCode() << ")";
        log_errors << "SQLString: " << sentence;
        return false;
    }
    return true;
}

SqlQuery::SqlResultset SqlQuery::GetLastResultSet() {
    do {
        instance().sql_qrsl.reset( instance().sql_stmt->getResultSet() );
    } while( instance().sql_stmt->getMoreResults() );
    return instance().sql_qrsl;
}

SqlQuery::SqlResultset SqlQuery::ExecuteProcedure(std::string sentence) {
    auto rsl = Execute(sentence);
    if( !rsl )
        return nullptr;
    return GetLastResultSet();
}

bool SqlQuery::ExecuteUpdateProcedure(std::string sentence) {
    auto rsl = Execute(sentence);
    if( !rsl )
        return rsl;
    auto rsl_ = GetLastResultSet();
    if( rsl_ && rsl_->first() ) {
        log_errors << rsl_->getString("Level") << "(" << rsl_->getString("Code") << ") " << rsl_->getString("Message");
        log_errors << "Query: " << sentence;
        return false;
    }
    return true;
}

}   //namespace
}