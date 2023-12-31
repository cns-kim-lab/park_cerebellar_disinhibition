#ifndef EVENTHANDLER_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
#define EVENTHANDLER_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD

#if !defined(__GNUC__) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || (__GNUC__ >= 4) // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif

#include "yaml-cpp-old/anchor.h"
#include <string>

namespace YAMLold
{
	struct Mark;
	
	class EventHandler
	{
	public:
		virtual ~EventHandler() {}

		virtual void OnDocumentStart(const Mark& mark) = 0;
		virtual void OnDocumentEnd() = 0;
		
		virtual void OnNull(const Mark& mark, anchor_t anchor) = 0;
		virtual void OnAlias(const Mark& mark, anchor_t anchor) = 0;
		virtual void OnScalar(const Mark& mark, const std::string& tag, anchor_t anchor, const std::string& value) = 0;

		virtual void OnSequenceStart(const Mark& mark, const std::string& tag, anchor_t anchor) = 0;
		virtual void OnSequenceEnd() = 0;

		virtual void OnMapStart(const Mark& mark, const std::string& tag, anchor_t anchor) = 0;
		virtual void OnMapEnd() = 0;
	};
}

#endif // EVENTHANDLER_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD

