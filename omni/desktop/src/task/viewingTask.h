#pragma once
#include "precomp.h"

#include "task/task.h"
#include "common/common.h"

#include "network/sqlQuery.h"

namespace om {
namespace task {

class ViewingTask : virtual public Task {
  public:
    ViewingTask();
    ViewingTask(om::network::SqlQuery::SqlResultset rsl);
    virtual ~ViewingTask();

    virtual uint64_t Id() const override { return id_; }
    virtual uint64_t CellId() const override { return cellId_; }
    virtual std::string Path() const { return path_; }
    virtual std::string Notes() const override { return notes_; }
    virtual bool Reaping() const override { return false; }
    virtual const std::vector<SegGroup>& SegGroups() const { return groups_; }
    virtual bool Start() override;
    virtual bool Submit() override;
    virtual bool Save() override; 
    virtual bool Skip() override;
    virtual std::string Taskfrom() const override { return taskfrom_; }

  private:
    uint64_t id_;
    uint64_t cellId_;
    std::string path_;
    std::string notes_;
    common::SegIDSet segments_;
    std::vector<SegGroup> groups_;
    std::string taskfrom_;
}; //class  

}   // namespace om::task::
}   // namespace om::
