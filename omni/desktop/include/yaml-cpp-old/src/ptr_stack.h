#ifndef PTR_STACK_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
#define PTR_STACK_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD

#if !defined(__GNUC__) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || (__GNUC__ >= 4) // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif

#include <cstddef>
#include "yaml-cpp-old/noncopyable.h"
#include <memory>
#include <vector>

template <typename T>
class ptr_stack: private YAMLold::noncopyable
{
public:
	ptr_stack() {}
	~ptr_stack() { clear(); }
	
	void clear() {
		for(unsigned i=0;i<m_data.size();i++)
			delete m_data[i];
		m_data.clear();
	}
	
	std::size_t size() const { return m_data.size(); }
	bool empty() const { return m_data.empty(); }
	
	void push(std::auto_ptr<T> t) {
		m_data.push_back(NULL);
		m_data.back() = t.release();
	}
	std::auto_ptr<T> pop() {
		std::auto_ptr<T> t(m_data.back());
		m_data.pop_back();
		return t;
	}
	T& top() { return *m_data.back(); }
	const T& top() const { return *m_data.back(); }
	
private:
	std::vector<T*> m_data;
};

#endif // PTR_STACK_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
