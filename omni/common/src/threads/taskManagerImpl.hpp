#pragma once

//
// Copyright (C) 2010  Aleksandar Zlateski <zlateski@mit.edu>
// ----------------------------------------------------------
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#include "precomp.h"
#include "common/stoppable.h"
#include "threads/threadPoolManager.h"

namespace om {
namespace thread {

template <class TaskContainer>
class TaskManagerImpl
    : public zi::runnable,
      public zi::enable_shared_from_this<TaskManagerImpl<TaskContainer>>,
      public common::stoppable {
  typedef zi::shared_ptr<zi::concurrency_::runnable> task_t;

  enum state {
    IDLE = 0,
    STARTING,
    RUNNING,
    STOPPING
  };

  std::size_t worker_count_;
  std::size_t worker_limit_;
  std::size_t idle_workers_;
  std::size_t active_workers_;
  std::size_t max_size_;

  state state_;

  zi::mutex mutex_;
  zi::condition_variable workers_cv_;
  zi::condition_variable manager_cv_;

  TaskContainer& tasks_;

 public:
  TaskManagerImpl(const uint32_t worker_limit, const uint32_t max_size,
                  TaskContainer& tasks)
      : worker_count_(0),
        worker_limit_(worker_limit),
        idle_workers_(0),
        active_workers_(0),
        max_size_(max_size),
        state_(IDLE),
        tasks_(tasks) {
    ThreadPoolManager::Add(this);
  }

  ~TaskManagerImpl() {
    // remove before stopping (else threadPoolManager may also attempt to
    //   stop pool during its own shutdown...)
    ThreadPoolManager::Remove(this);
    stop();
  }

  std::size_t worker_count() {
    zi::mutex::guard g(mutex_);
    return worker_count_;
  }

  std::size_t worker_limit() {
    zi::mutex::guard g(mutex_);
    return worker_limit_;
  }

  std::size_t idle_workers() {
    zi::mutex::guard g(mutex_);
    return idle_workers_;
  }

  void StoppableStop() { join(); }

 private:
  void create_workers_nl(std::size_t count) {
    if (count <= 0 || active_workers_ >= worker_limit_) {
      return;
    }

    for (; count && active_workers_ <= worker_limit_;
         --count, ++active_workers_) {
      zi::thread t(this->shared_from_this());
      t.start();
    }

    manager_cv_.wait(mutex_);
  }

  void kill_workers_nl(std::size_t count) {
    if (count <= 0 || active_workers_ <= 0) {
      return;
    }

    active_workers_ = (count > active_workers_) ? 0 : active_workers_ - count;

    workers_cv_.notify_all();

    while (worker_count_ != active_workers_) {
      manager_cv_.wait(mutex_);
    }
  }

 public:
  void add_workers(std::size_t count) {
    zi::mutex::guard g(mutex_);

    if (count <= 0) {
      return;
    }

    worker_limit_ += count;

    if (state_ == IDLE || state_ == STOPPING) {
      return;
    }

    create_workers_nl(count);
  }

  void remove_workers(std::size_t count) {
    zi::mutex::guard g(mutex_);

    if (count <= 0 || worker_limit_ <= 0) {
      return;
    }

    count = (count > worker_limit_) ? worker_limit_ : count;

    worker_limit_ -= count;

    if (state_ == IDLE || state_ == STOPPING) {
      return;
    }

    kill_workers_nl(count);
  }

  bool start() {
    zi::mutex::guard g(mutex_);

    if (state_ != IDLE) {
      return false;
    }

    ZI_ASSERT_0(worker_count_);
    ZI_ASSERT_0(idle_workers_);

    state_ = STARTING;

    create_workers_nl(worker_limit_);

    state_ = RUNNING;
    // workers_cv_.notify_all(); todo: pause?

    return true;
  }

  void stop(bool and_join = false) {
    zi::mutex::guard g(mutex_);

    if (state_ != RUNNING) {
      return;
    }

    state_ = STOPPING;

    if (!and_join) {
      tasks_.clear();
    }

    kill_workers_nl(active_workers_);
    state_ = IDLE;
  }

  void join() { stop(true); }

  void wake_all() {
    zi::mutex::guard g(mutex_);

    if (state_ == RUNNING && idle_workers_ > 0) {
      workers_cv_.notify_all();
    }
  }

  void run() {
    {
      zi::mutex::guard g(mutex_);
      ++worker_count_;

      if (worker_count_ == active_workers_) {
        manager_cv_.notify_one();
      }
    }

    task_t task;

    for (bool active = true; active;) {
      {
        zi::mutex::guard g(mutex_);

        while (worker_count_ <= active_workers_ && tasks_.empty()) {
          ++idle_workers_;
          workers_cv_.wait(g);
          --idle_workers_;
        }

        if (worker_count_ <= active_workers_ ||
            (state_ == STOPPING && tasks_.size())) {
          if (tasks_.size()) {
            task = tasks_.get_front();
          }
        } else {
          --worker_count_;
          if (worker_count_ == active_workers_) {
            manager_cv_.notify_one();
          }
          return;
        }
      }

      if (task) {
        task->execute();
        task.reset();
      }
    }
  }
};

}  // namespace threads
}  // namespace om
