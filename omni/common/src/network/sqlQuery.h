#pragma once
#include "precomp.h"
#include "zi/utility.h"

#define DEFAULT_SQL_PORT   3306
#include "mysql_connection.h"
#include <cppconn/driver.h>
#include <cppconn/exception.h>
#include <cppconn/resultset.h>
#include <cppconn/statement.h>

namespace om {
namespace network {
enum class SqlConnectResult {
  SUCCESS,
  CONNECTION_ERROR,
  INVALID_CON_INFO,
};

class SqlQuery : private om::SingletonBase<SqlQuery> {
    public:
        typedef std::unique_ptr<sql::Connection> SqlConnection;
        typedef std::unique_ptr<sql::Statement> SqlStatement;
        typedef std::shared_ptr<sql::ResultSet> SqlResultset;

        static SqlConnectResult Connect(std::string address_, uint32_t port_, std::string username_);
        static SqlResultset GetLastResultSet();
        static bool Execute(std::string sentence);
        static SqlResultset ExecuteProcedure(std::string sentence);
        static bool ExecuteUpdateProcedure(std::string sentence);

    private:
        SqlQuery();
        ~SqlQuery();

        std::string host;
        uint32_t port;

        sql::Driver* sql_drv;
        SqlConnection sql_con;
        SqlStatement sql_stmt;
        SqlResultset sql_qrsl;

        friend class zi::singleton<SqlQuery>;
};
}   //namesapce
}