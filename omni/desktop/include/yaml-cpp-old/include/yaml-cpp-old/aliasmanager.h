#ifndef ALIASMANAGER_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
#define ALIASMANAGER_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD

#if !defined(__GNUC__) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || (__GNUC__ >= 4) // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif

#include "yaml-cpp-old/anchor.h"
#include <map>

namespace YAMLold
{
	class Node;
	
	class AliasManager
	{
	public:
		AliasManager();
		
		void RegisterReference(const Node& node);
		anchor_t LookupAnchor(const Node& node) const;
		
	private:
		anchor_t _CreateNewAnchor();
		
	private:
		typedef std::map<const Node*, anchor_t> AnchorByIdentity;
		AnchorByIdentity m_anchorByIdentity;
		
		anchor_t m_curAnchor;
	};
}

#endif // ALIASMANAGER_H_62B23520_7C8E_11DE_8A39_0800200C9A66_OLD
